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
    final lines = type('2*20+90+120+90*2').lines;
    expect(lines.map((l) => l.expression).toList(), [
      '2 × 20',
      '90',
      '120',
      '90 × 2',
    ]);
    expect(lines.map((l) => l.quantity).toList(), [20, 1, 1, 2]);
    expect(lines.map((l) => l.amount).toList(), [40, 90, 120, 180]);
  });

  test('total quantity from the mockup expression', () {
    final e = type('2*20+90+120+90*2');
    expect(e.value, 430);
    expect(e.totalQuantity, 24);
  });

  test('uses the second multiplication factor as quantity', () {
    final e = type('980*5');

    expect(e.value, 4900);
    expect(e.lines.single.quantity, 5);
    expect(e.totalQuantity, 5);
  });

  test('non-whole multiplication factors remain one custom line item', () {
    expect(type('980*0.5').totalQuantity, 1);
    expect(type('980*10%').totalQuantity, 1);
  });
}
