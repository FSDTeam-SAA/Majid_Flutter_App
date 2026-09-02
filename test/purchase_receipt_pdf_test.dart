import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/invoice/presentation/utils/invoice_pdf_builder.dart';
import 'package:majid_flutter_app/features/invoice/presentation/utils/purchase_receipt_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  test('renders the purchase receipt', () async {
    final file = await PurchaseReceiptPdf.build(
      fileNamePrefix: 'purchase_receipt',
      createdAt: DateTime(2026, 9, 1, 16, 43),
      shopName: '',
      shopAddress: '',
      shopPhone: '',
      shopEmail: 'sumantachtg@gmail.com',
      preparedBy: 's de',
      customerName: 'sr suman',
      customerPhone: '0158411211',
      customerEmail: 'sumantachtg1@gmail.com',
      customerAddress: 'D, HAKA',
      customerIdNumber: '5145155',
      items: const [
        InvoicePdfItem(
          name: 'net',
          code: '5tb • gold',
          imeiSerial: '861142051584447',
          quantity: 1,
          unitPrice: 2,
        ),
      ],
      totalAmount: 2,
      currencyCode: 'BDT',
    );

    final out = File('${Directory.systemTemp.path}/purchase_preview.pdf');
    await file.copy(out.path);
    expect(await out.length(), greaterThan(1000));
  });
}
