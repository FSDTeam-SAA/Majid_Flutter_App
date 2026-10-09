import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:majid_flutter_app/features/invoice/presentation/pages/record_payment_page.dart';
import 'package:majid_flutter_app/features/profile/presentation/controller/profile_controller.dart';

class _Profile extends ProfileController {
  @override
  // ignore: must_call_super
  void onInit() {}
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<ProfileController>(_Profile());
  });
  tearDown(() => Get.reset());

  testWidgets(
    'bank selection is preserved and submitted only on confirmation',
    (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RecordPaymentPage(
            invoiceTotal: 50,
            availableCash: 200,
            initialCashSelected: false,
            onSubmitPayment: ({required paymentMethod}) async {
              submitted.add(paymentMethod);
              return null;
            },
          ),
        ),
      );
      expect(find.text('CUSTOMER BANK TRANSFER DETAILS'), findsOneWidget);
      expect(submitted, isEmpty);
      final accountHolder = find.widgetWithText(
        TextField,
        'Account Holder Name*',
      );
      await tester.enterText(accountHolder, 'Test Customer');
      await tester.ensureVisible(find.text('Mark as Paid'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark as Paid'));
      await tester.pumpAndSettle();
      expect(submitted, ['bank_transfer']);
      // A failed save retains the selected method and entered bank details.
      expect(find.text('CUSTOMER BANK TRANSFER DETAILS'), findsOneWidget);
      expect(find.text('Test Customer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'switching to cash updates selection without submitting payment',
    (tester) async {
      final submitted = <String>[];
      final choices = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: RecordPaymentPage(
            invoiceTotal: 50,
            availableCash: 200,
            initialCashSelected: false,
            onPaymentMethodChanged: choices.add,
            onSubmitPayment: ({required paymentMethod}) async {
              submitted.add(paymentMethod);
              return null;
            },
          ),
        ),
      );
      await tester.tap(find.text('Pay from Available Cash'));
      await tester.pumpAndSettle();
      expect(choices, [true]);
      expect(submitted, isEmpty);
      expect(find.text('CUSTOMER BANK TRANSFER DETAILS'), findsNothing);
      await tester.ensureVisible(find.text('Pay from Cash'));
      await tester.tap(find.text('Pay from Cash'));
      await tester.pumpAndSettle();
      expect(submitted, ['cash']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bank transfer receipt leaves available cash unchanged', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: RecordPaymentPage(
          invoiceTotal: 50,
          availableCash: 200,
          initialCashSelected: false,
          onSubmitPayment: ({required paymentMethod}) async =>
              File('/tmp/test-purchase-receipt.pdf'),
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Account Holder Name*'),
      'Test Customer',
    );
    await tester.ensureVisible(find.text('Mark as Paid'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as Paid'));
    await tester.pumpAndSettle();
    expect(find.text('Bank Transfer'), findsOneWidget);
    expect(find.text('£200.00'), findsOneWidget);
    expect(find.text('£150.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
