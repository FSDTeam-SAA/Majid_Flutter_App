import 'dart:io';
import 'dart:convert';
import 'package:majid_flutter_app/features/customer/domain/entities/customer.dart';
import 'package:majid_flutter_app/features/customer/domain/entities/outstanding_invoice.dart';
import 'package:majid_flutter_app/features/customer/presentation/widgets/balance_payment_sheet.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:majid_flutter_app/core/network/api_service/api_client.dart';
import 'package:majid_flutter_app/features/profile/presentation/controller/profile_controller.dart';
import 'package:majid_flutter_app/features/stock/presentation/utils/checkout_payment.dart';
import 'package:majid_flutter_app/features/invoice/presentation/utils/verified_invoice_pdf.dart';

class _Profile extends ProfileController {
  // Skip network initialization in this isolated payment-selection test.
  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  String get userId => 'shop-test';
}

class _InvoiceApi extends ApiClient {
  _InvoiceApi({
    required this.fail,
    this.failBalances = false,
    this.balanceCurrency = 'GBP',
  }) : super('https://example.test');
  final bool fail;
  final bool failBalances;
  final String balanceCurrency;
  int calls = 0;
  FormData? payload;
  @override
  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    if (failBalances) {
      throw DioException(requestOptions: RequestOptions(path: path));
    }
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'data': [
          {
            '_id': '507f1f77bcf86cd799439011',
            'invoiceNumber': 'OLD-1',
            'totalAmount': 80,
            'amountPaid': 40,
            'dueAmount': 40,
            'currency': balanceCurrency,
          },
          {
            '_id': '507f1f77bcf86cd799439012',
            'invoiceNumber': 'OLD-2',
            'totalAmount': 15,
            'dueAmount': 15,
            'currency': 'GBP',
          },
        ],
      },
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) async {
    calls++;
    payload = data as FormData;
    final options = RequestOptions(path: path);
    if (fail) {
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 409,
          data: {'message': 'Repair already collected'},
        ),
      );
    }
    return Response(
      requestOptions: options,
      statusCode: 201,
      data: {
        'success': true,
        'data': {
          '_id': 'saved-invoice',
          'invoice': {'url': 'https://example.test/invoice.pdf'},
        },
      },
    );
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ProfileController>(_Profile());
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });
  tearDown(() => Get.reset());
  for (final balancesFail in [false, true]) {
    testWidgets(
      balancesFail
          ? 'failed balance lookup still allows today only, without a payment write'
          : 'different currencies cannot be combined in Pay All',
      (tester) async {
        final api = _InvoiceApi(
          fail: false,
          failBalances: balancesFail,
          balanceCurrency: balancesFail ? 'GBP' : 'USD',
        );
        List<OutstandingInvoice>? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  child: const Text('Choose balances'),
                  onPressed: () async {
                    selected = await chooseBalancePayment(
                      context,
                      api: api,
                      customerId: 'customer-test',
                      today: 130,
                      currencyCode: 'GBP',
                      currencySymbol: '£',
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Choose balances'));
        await tester.pumpAndSettle();
        if (balancesFail) {
          expect(find.text('Retry balances'), findsOneWidget);
          expect(find.textContaining('Pay All ·'), findsNothing);
        } else {
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull,
          );
        }
        await tester.tap(find.textContaining('Pay Total Today Only ·'));
        await tester.pumpAndSettle();
        expect(selected, isEmpty);
        expect(api.calls, 0);
        expect(tester.takeException(), isNull);
        api.dio.close();
      },
    );
  }
  testWidgets(
    'cancelling previous invoice selection does not save or clear checkout',
    (tester) async {
      final api = _InvoiceApi(fail: false);
      bool? result;
      int cleared = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('Charge'),
                onPressed: () async {
                  result = await recordCheckoutPayment(
                    context,
                    apiClient: api,
                    customer: Customer(
                      id: 'customer-test',
                      firstName: 'Test',
                      lastName: '',
                      email: '',
                      phone: '',
                      address: '',
                      createdAt: DateTime(2026),
                    ),
                    items: const [
                      VerifiedInvoiceItem(
                        name: 'Repair',
                        quantity: 1,
                        lineTotal: 130,
                      ),
                    ],
                    onRecorded: () => cleared++,
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Charge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cash'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, false);
      expect(api.calls, 0);
      expect(cleared, 0);
      expect(tester.takeException(), isNull);
      api.dio.close();
    },
  );
  for (final method in ['Cash', 'Card']) {
    testWidgets(
      'Charge prompts for $method and cancelling does not record payment',
      (tester) async {
        bool? result;
        int recorded = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TextButton(
                child: const Text('Charge'),
                onPressed: () async {
                  result = await recordCheckoutPayment(
                    tester.element(find.text('Charge')),
                    items: const [
                      VerifiedInvoiceItem(
                        name: 'Repair',
                        quantity: 1,
                        lineTotal: 100,
                      ),
                    ],
                    onRecorded: () => recorded++,
                  );
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('Charge'));
        await tester.pumpAndSettle();
        expect(find.text('Choose payment method'), findsOneWidget);
        expect(find.text('Cash'), findsOneWidget);
        expect(find.text('Card'), findsOneWidget);
        await tester.tap(find.text(method));
        await tester.pumpAndSettle();
        expect(find.text('Payment received'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(result, false);
        expect(recorded, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final fail in [false, true]) {
    testWidgets(
      fail
          ? 'failed payment keeps the checkout draft and does not retry'
          : 'confirmed payment saves paid invoice before clearing the checkout draft',
      (tester) async {
        final api = _InvoiceApi(fail: fail);
        bool? result;
        int cleared = 0;
        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              body: TextButton(
                child: const Text('Charge'),
                onPressed: () async {
                  result = await recordCheckoutPayment(
                    tester.element(find.text('Charge')),
                    apiClient: api,
                    repairIds: ['repair-test'],
                    stockLines: const [
                      {'itemId': 'stock-test', 'quantity': 1},
                    ],
                    items: const [
                      VerifiedInvoiceItem(
                        name: 'Repair and case',
                        quantity: 1,
                        lineTotal: 130,
                      ),
                    ],
                    onRecorded: () => cleared++,
                  );
                },
              ),
            ),
          ),
        );
        await tester.tap(find.text('Charge'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cash'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Payment received'));
        for (var i = 0; i < 100 && api.calls == 0 && result == null; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(api.calls, 1);
        final fields = Map.fromEntries(api.payload!.fields);
        expect(fields['paymentStatus'], 'paid');
        expect(fields['amountPaid'], '130.0');
        expect(fields['dueAmount'], '0');
        expect(fields['repairRequestId'], 'repair-test');
        expect(api.payload!.files, hasLength(1));
        expect(cleared, fail ? 0 : 1);
        if (!fail) {
          expect(find.text('Print'), findsOneWidget);
          await tester.tap(find.text('Done'));
          await tester.pumpAndSettle();
        }
        expect(result, !fail);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        api.dio.close();
      },
    );
  }
  for (final all in [false, true]) {
    testWidgets(
      all
          ? 'Pay All settles previous balances without adding them to today invoice total'
          : 'Today Only leaves previous invoices unchanged',
      (tester) async {
        final api = _InvoiceApi(fail: false);
        int recorded = 0;
        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              body: TextButton(
                child: const Text('Charge'),
                onPressed: () => recordCheckoutPayment(
                  tester.element(find.text('Charge')),
                  apiClient: api,
                  customer: Customer(
                    id: 'customer-test',
                    firstName: 'Test',
                    lastName: 'Customer',
                    email: 'customer@example.com',
                    phone: '',
                    address: '',
                    createdAt: DateTime(2026),
                  ),
                  items: const [
                    VerifiedInvoiceItem(
                      name: 'Repair',
                      quantity: 1,
                      lineTotal: 130,
                    ),
                  ],
                  onRecorded: () => recorded++,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Charge'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cash'));
        await tester.pumpAndSettle();
        expect(api.calls, 0);
        await tester.tap(
          find.textContaining(all ? 'Pay All ·' : 'Pay Total Today Only ·'),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining(all ? '185.00' : '130.00'), findsOneWidget);
        await tester.tap(find.text('Payment received'));
        for (var i = 0; i < 100 && api.calls == 0; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(api.calls, 1);
        final fields = Map.fromEntries(api.payload!.fields);
        expect(fields['totalAmount'], '130.0');
        expect(fields['amountPaid'], '130.0');
        expect(fields['dueAmount'], '0');
        if (all) {
          final allocations = jsonDecode(fields['allocations']!);
          expect(allocations, [
            {'invoiceId': '507f1f77bcf86cd799439011', 'amountApplied': 40.0},
            {'invoiceId': '507f1f77bcf86cd799439012', 'amountApplied': 15.0},
          ]);
        } else {
          expect(fields.containsKey('allocations'), isFalse);
        }
        expect(recorded, 1);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        api.dio.close();
      },
    );
  }
}
