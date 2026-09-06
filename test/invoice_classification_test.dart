import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/invoice/domain/entities/invoice.dart';

Invoice _invoice(String type) =>
    Invoice(id: 'x', type: type, customerName: 'test');

void main() {
  test('classifies both the app\'s short codes and full-phrase legacy types', () {
    // What the app itself sends when creating an invoice.
    expect(_invoice('purchase').classification, 'Purchase Invoice');
    expect(_invoice('delivery').classification, 'Delivery Note');
    expect(_invoice('Custom invoice').classification, 'Custom Invoice');

    // What older / website-created invoices apparently store already.
    expect(_invoice('Purchase Invoice').classification, 'Purchase Invoice');
    expect(_invoice('Delivery Note').classification, 'Delivery Note');

    // Only "Custom Invoice" is refundable.
    expect(_invoice('purchase').isRefundable, false);
    expect(_invoice('delivery').isRefundable, false);
    expect(_invoice('Custom invoice').isRefundable, true);
  });
}
