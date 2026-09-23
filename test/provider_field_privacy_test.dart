import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/scan/presentation/pages/device_report_page.dart';
import 'package:majid_flutter_app/features/scan/presentation/utils/provider_field_privacy.dart';

void main() {
  test('blocks provider account and transport metadata', () {
    for (final key in [
      'balance',
      'available_balance',
      'PRICE',
      'service-price',
      'provider_cost',
      'id',
      'request_id',
      'status',
      'ip',
      'IP Address',
      'api_key',
      'access_token',
      'result',
    ]) {
      expect(
        isCustomerSafeProviderField(key),
        isFalse,
        reason: '$key must not be exposed in a customer report',
      );
    }
  });

  test('keeps customer-safe device facts', () {
    for (final key in [
      'product_version',
      'coverage_status',
      'purchase_country',
      'next_tether_policy',
      'imei_number',
      'activation_status',
      'blacklist_status',
    ]) {
      expect(
        isCustomerSafeProviderField(key),
        isTrue,
        reason: '$key is a device fact and should remain visible',
      );
    }
  });

  testWidgets('device report never renders provider business metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeviceReportPage(
          report: {
            'imei': '1987871701',
            'data': {
              'providerData': {
                'product_version': '27.0',
                'balance': 349.626,
                'price': '1.00',
                'id': 197871701,
                'status': 'success',
                'ip': '187.124.208.126',
              },
            },
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('PRODUCT VERSION'), findsOneWidget);
    expect(find.text('27.0'), findsOneWidget);
    expect(find.text('BALANCE'), findsNothing);
    expect(find.text('349.626'), findsNothing);
    expect(find.text('PRICE'), findsNothing);
    expect(find.text('1.00'), findsNothing);
    expect(find.text('IP'), findsNothing);
    expect(find.text('187.124.208.126'), findsNothing);
  });
}
