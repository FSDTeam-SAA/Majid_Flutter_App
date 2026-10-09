import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/core/utils/invoice_template_settings.dart';
import 'package:majid_flutter_app/features/invoice/presentation/utils/invoice_template_builder.dart';
import 'package:majid_flutter_app/features/invoice/presentation/utils/verified_invoice_pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  test(
    'an unsynced local theme is not overwritten by an older server setting',
    () async {
      await InvoiceTemplateSettings.save('neo-bold', localSelection: true);
      await InvoiceTemplateSettings.syncFromProfile('classic-editorial');
      expect(InvoiceTemplateSettings.activeId, 'neo-bold');
      await InvoiceTemplateSettings.save('neo-bold');
      await InvoiceTemplateSettings.syncFromProfile('default');
      expect(InvoiceTemplateSettings.activeId, 'default');
    },
  );

  for (final theme in InvoiceTemplateSettings.templates) {
    test(
      'renders ${theme.id} with multi-quantity lines and repair tracking',
      () async {
        final file = await InvoiceTemplateBuilder.buildSalesInvoice(
          templateId: theme.id,
          fileName: 'feedback_${theme.id}.pdf',
          invoiceNumber: 'INV-TEST',
          createdAt: DateTime(2026, 10, 8),
          shopName: 'Test Repair Shop',
          shopEmail: 'shop@example.com',
          shopPhone: '+44123456789',
          customerName: 'Test Customer',
          customerEmail: 'customer@example.com',
          customerPhone: '+44123456789',
          customerAddress: 'Test Road',
          paymentLabel: 'Cash',
          isPaid: true,
          currencySymbol: 'GBP',
          currencyCode: 'GBP',
          servedBy: 'Test Staff',
          trackingUrl: 'https://imoscan.com/my-invoice/repair-test',
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
        expect(String.fromCharCodes(await file.openRead(0, 4).first), '%PDF');
      },
    );
  }
}
