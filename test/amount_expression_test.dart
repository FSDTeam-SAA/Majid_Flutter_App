import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/stock/presentation/utils/amount_expression.dart';

AmountExpression type(String keys) {
  var e = AmountExpression.empty;
  for (final k in keys.split('')) {
    if (k == '%') {
      e = e.addPercent();
    } else if ('+-*/'.contains(k)) {
      e = e.addOperator(k);
    } else if (k == '.') {
      e = e.addDecimal();
    } else {
      e = e.addDigit(k);
    }
  }
  return e;
}

void main() {
  test('splits the mockup expression into reviewable lines', () {
    final lines = type('20*2+90+120+2*90').lines;
    expect(lines.map((l) => l.expression).toList(), [
      '20 × 2',
      '90',
      '120',
      '2 × 90',
    ]);
    expect(lines.map((l) => l.quantity).toList(), [20, 1, 1, 2]);
    expect(lines.map((l) => l.amount).toList(), [40, 90, 120, 180]);
  });

  test('total quantity from the mockup expression', () {
    final e = type('20*2+90+120+2*90');
    expect(e.value, 430);
    expect(e.totalQuantity, 24);
  });
}
