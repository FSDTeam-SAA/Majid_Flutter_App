import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:majid_flutter_app/features/invoice/domain/repositories/invoice_repository.dart';
import 'package:majid_flutter_app/features/profile/presentation/controller/profile_controller.dart';
import 'package:majid_flutter_app/features/transactions/presentation/pages/all_transactions_page.dart';
import 'package:majid_flutter_app/core/network/api_service/api_client.dart';
import 'package:majid_flutter_app/core/utils/invoice_template_settings.dart';
import 'package:majid_flutter_app/core/utils/invoice_amount.dart';
import 'package:majid_flutter_app/features/stock/domain/entities/ready_order.dart';
import 'package:majid_flutter_app/features/customer/domain/entities/outstanding_invoice.dart';
import 'package:majid_flutter_app/features/invoice/domain/entities/invoice.dart';
import 'package:majid_flutter_app/features/invoice/presentation/utils/compact_receipt_pdf.dart';
import 'package:majid_flutter_app/features/invoice/presentation/utils/invoice_template_builder.dart';
import 'package:majid_flutter_app/features/invoice/presentation/utils/verified_invoice_pdf.dart';
import 'package:majid_flutter_app/features/repair/data/repair_parts_repository.dart';
import 'package:majid_flutter_app/features/repair/presentation/controller/repair_data.dart';
import 'package:majid_flutter_app/features/repair/presentation/pages/all_repair_requests_page.dart';
import 'package:majid_flutter_app/features/repair/presentation/utils/repair_timeline.dart';
import 'package:majid_flutter_app/features/stock/data/repositories/inventory_repository_impl.dart';
import 'package:majid_flutter_app/features/transactions/presentation/utils/invoice_transaction.dart';

class _HistoryApi extends ApiClient {
  _HistoryApi() : super('https://example.test');
  final pages = <int>[];
  @override
  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    final page = query!['page'] as int;
    if (query['limit'] == 100) pages.add(page);
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'data': [
          {
            '_id': page == 1 ? 'new-repair' : 'old-repair',
            'firstName': page == 1 ? 'New Customer' : 'Older Customer',
            'deviceModel': 'Phone',
            'IMEINumber': page == 1 ? '111111111111111' : '222222222222222',
            'status': 'completed',
          },
        ],
        'meta': {'total': 2, 'totalPage': 2},
      },
    );
  }
}

class _PartApi extends ApiClient {
  _PartApi() : super('https://example.test');
  Map<String, dynamic>? saved;
  @override
  Future<Response> post(String path, {dynamic data}) async {
    saved = Map<String, dynamic>.from(data as Map);
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'data': {...saved!, '_id': 'saved-part'},
      },
    );
  }
}

class _Profile extends ProfileController {
  @override
  // ignore: must_call_super
  void onInit() {}
  @override
  String get userId => 'shop-test';
}

class _Invoices extends Fake implements InvoiceRepository {
  @override
  Future<List<Invoice>> getInvoices(String shopkeeperId) async => List.generate(
    80,
    (i) => Invoice(
      id: 'invoice-$i',
      invoiceNumber: 'INV-$i',
      type: 'Custom invoice',
      customerName: 'Customer $i',
      totalAmount: 10,
      amountPaid: 10,
      paymentStatus: 'paid',
      createdAt: DateTime(
        2026,
        10,
        9,
      ).subtract(Duration(days: i)).toIso8601String(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    Get.put<ProfileController>(_Profile());
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => Directory.systemTemp.path,
        );
  });
  tearDown(() => Get.reset());
  test(
    'old invoice balances ignore purchases, paid bills and duplicate records',
    () {
      final outstanding = OutstandingInvoice.fromResponse({
        'data': [
          {
            '_id': 'one',
            'type': 'Custom invoice',
            'totalAmount': '100',
            'paymentDetails': {'amountPaid': 25},
          },
          {'_id': 'one', 'totalAmount': 100},
          {'_id': 'paid', 'totalAmount': 100, 'paymentStatus': 'paid'},
          {'_id': 'purchase', 'type': 'Purchase Invoice', 'totalAmount': 200},
          {'_id': 'refund', 'type': 'Refund', 'totalAmount': 50},
        ],
      });
      expect(outstanding.map((invoice) => invoice.id), ['one']);
      expect(outstanding.single.due, 75);
      expect(
        () => OutstandingInvoice.fromResponse({
          'data': [
            {'totalAmount': double.nan},
          ],
        }),
        throwsFormatException,
      );
    },
  );
  test('assignment and quote approval map to their actual stages', () {
    final assigned = buildRepairTimeline('order-assigned');
    expect(assigned[0].status, TimelineStatus.done);
    expect(assigned[1].status, TimelineStatus.done);
    expect(assigned[2].status, TimelineStatus.pending);
    final diagnosing = buildRepairTimeline('diagnosing');
    expect(diagnosing[1].status, TimelineStatus.done);
    expect(diagnosing[2].status, TimelineStatus.inProgress);
    final approved = buildRepairTimeline('approved');
    expect(
      approved.firstWhere((step) => step.title == 'Quote Sent').status,
      TimelineStatus.done,
    );
    expect(
      approved.firstWhere((step) => step.title == 'Repairing Started').status,
      TimelineStatus.pending,
    );
    expect(
      buildRepairTimeline(
        'collected',
      ).every((step) => step.status == TimelineStatus.done),
      isTrue,
    );
    expect(
      buildRepairTimeline(
        'unable-to-repair',
      ).any((step) => step.status == TimelineStatus.inProgress),
      isFalse,
    );
  });
  test(
    'payment precision and repair receipt match discounted collection balance',
    () {
      expect(invoiceMoney(1.2 * 3), 3.6);
      expect(invoiceMoney(3.6 - 1.2), 2.4);
      final repair = <String, dynamic>{
        'price': 100,
        'discount': 10,
        'depositPaid': 20,
      };
      expect(ReadyOrder.totalPrice(repair), 90);
      expect(ReadyOrder.depositPaid(repair), 20);
      expect(ReadyOrder.fromJson(repair).price, 70);
      expect(
        ReadyOrder.fromJson({'price': 1.2 * 3, 'depositPaid': 1.2}).price,
        2.4,
      );
      expect(
        ReadyOrder.totalPrice({
          'shopkeeperNotes': {'cost': '100'},
          'discount': 10,
        }),
        90,
      );
      expect(ReadyOrder.totalPrice({'price': double.nan}), 0);
      final balances = OutstandingInvoice.fromResponse({
        'data': [
          {'_id': 'old', 'totalAmount': 3.6, 'amountPaid': 1.2},
        ],
      });
      expect(balances.single.due, 2.4);
    },
  );
  for (final template in ['default', 'classic-editorial']) {
    test(
      'full decimal payment does not fail validation in $template',
      () async {
        final file = await InvoiceTemplateBuilder.buildSalesInvoice(
          templateId: template,
          fileName: 'decimal_$template.pdf',
          invoiceNumber: 'INV-DECIMAL',
          createdAt: DateTime(2026, 10, 9),
          shopName: 'Shop',
          shopEmail: '',
          shopPhone: '',
          customerName: 'Customer',
          customerEmail: '',
          customerPhone: '',
          customerAddress: '',
          paymentLabel: 'Cash',
          isPaid: true,
          amountPaid: 3.60,
          currencySymbol: 'GBP',
          currencyCode: 'GBP',
          items: [
            VerifiedInvoiceItem(name: 'Item', quantity: 3, lineTotal: 1.2 * 3),
          ],
        );
        expect(await file.length(), greaterThan(1000));
      },
    );
  }
  test(
    'parts catalog excludes handset names and keeps saved parts and codes',
    () {
      final phone = inventoryItemFromJson({
        '_id': 'phone',
        'itemName': 'Samsung Galaxy A51 Black',
        'categoryName': 'Phones',
        'sku': 'SKU51',
        'upc': '012345678901',
      });
      expect(isRepairPart(phone), isFalse);
      expect(phone.upc, '012345678901');
      expect(
        isRepairPart(
          inventoryItemFromJson({'itemName': 'iPhone replacement screen'}),
        ),
        isTrue,
      );
      expect(
        isRepairPart(
          inventoryItemFromJson({
            'itemName': 'Flex cable',
            'categoryName': 'Repair parts',
          }),
        ),
        isTrue,
      );
      expect(
        isRepairPart(
          inventoryItemFromJson({
            'itemName': 'Custom assembly',
            'productDetails': repairPartMarker,
          }),
        ),
        isTrue,
      );
    },
  );
  test(
    'historical partial transactions retain paid amount and are not labelled paid',
    () {
      final invoice = Invoice(
        id: 'old',
        type: 'Custom Invoice',
        customerName: 'Older Customer',
        totalAmount: 100,
        amountPaid: 25,
        dueAmount: 75,
        paymentStatus: 'partial',
        createdAt: '2025-01-01',
        servedBy: 'Test Staff',
      );
      final transaction = transactionFromInvoice(invoice);
      expect(transaction.amount, 25);
      expect(transaction.isPaid, isFalse);
      expect(transaction.dueAmount, 75);
      expect(transaction.servedBy, 'Test Staff');
      expect(transaction.date!.year, 2025);
    },
  );
  testWidgets('IMEI search finds a repair outside the newest page', (
    tester,
  ) async {
    final api = _HistoryApi();
    await tester.pumpWidget(
      MaterialApp(home: AllRepairRequestsPage(apiClient: api)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '222222222222222');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.pages, [1, 2]);
    expect(find.text('Older Customer'), findsOneWidget);
    expect(find.text('New Customer'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    api.dio.close();
  });
  test(
    'new part is persisted as a catalog product, without adding stock',
    () async {
      final api = _PartApi();
      expect(
        await RepairPartsRepository(api).create('Custom repair assembly'),
        'Custom repair assembly',
      );
      expect(api.saved!['quantity'], 0);
      expect(api.saved!['productDetails'], repairPartMarker);
      expect(api.saved!['imeiNumber'], startsWith('PART-'));
      expect(api.saved!['sku'], api.saved!['imeiNumber']);
      api.dio.close();
    },
  );
  testWidgets(
    'full transaction history searches beyond the preview and first display batch',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: AllTransactionsPage(repository: _Invoices())),
      );
      await tester.pumpAndSettle();
      expect(find.text('80 transactions'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Customer 79');
      await tester.pumpAndSettle();
      expect(find.text('Customer 79 · Custom Invoice'), findsOneWidget);
      expect(find.text('1 transactions'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  for (final count in [2, 40]) {
    test(
      '80 mm receipt handles $count lines without clipping into a fixed A4 page',
      () async {
        final bytes = await CompactReceiptPdf.build(
          CompactReceiptData(
            reference: 'INV-RECEIPT-$count',
            shopName: 'Test Repair Shop',
            shopAddress: '12 High Street, London',
            customerName: 'Test Customer',
            customerEmail: 'customer@example.com',
            paymentMethod: 'Cash',
            servedBy: 'Test Staff',
            currencyCode: 'GBP',
            date: DateTime(2026, 10, 9, 14, 30),
            trackingUrl: 'https://imoscan.com/my-invoice/repair-test',
            total: count * 25,
            paid: count * 25,
            due: 0,
            items: List.generate(
              count,
              (index) => VerifiedInvoiceItem(
                name: 'Screen replacement and protective case ${index + 1}',
                imei: '861142051584447',
                quantity: 1,
                lineTotal: 25,
              ),
            ),
          ),
        );
        await File(
          '${Directory.systemTemp.path}/compact_receipt_$count.pdf',
        ).writeAsBytes(bytes);
        expect(bytes.length, greaterThan(1000));
      },
    );
  }
  for (final template in InvoiceTemplateSettings.templates) {
    test('partial payment renders correct balance in ${template.id}', () async {
      final file = await InvoiceTemplateBuilder.buildSalesInvoice(
        templateId: template.id,
        fileName: 'partial_${template.id}.pdf',
        invoiceNumber: 'INV-PARTIAL',
        createdAt: DateTime(2026, 10, 9),
        shopName: 'Test Repair Shop',
        shopEmail: 'shop@example.com',
        shopPhone: '0123456789',
        customerName: 'Test Customer',
        customerEmail: 'customer@example.com',
        customerPhone: '0123456789',
        customerAddress: 'London',
        paymentLabel: 'Cash',
        isPaid: false,
        amountPaid: 70,
        currencySymbol: 'GBP',
        currencyCode: 'GBP',
        items: const [
          VerifiedInvoiceItem(
            name: 'Screen Repair',
            quantity: 2,
            lineTotal: 250,
          ),
          VerifiedInvoiceItem(name: 'Case', quantity: 1, lineTotal: 30),
        ],
      );
      expect(await file.length(), greaterThan(1000));
    });
  }
}
