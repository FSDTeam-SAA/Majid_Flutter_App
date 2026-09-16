import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:majid_flutter_app/features/stock/domain/entities/ready_order.dart';
import 'package:majid_flutter_app/features/stock/presentation/controller/checkout_draft_controller.dart';
import 'package:majid_flutter_app/features/stock/presentation/utils/amount_expression.dart';
import 'package:shared_preferences/shared_preferences.dart';

AmountExpression type(String keys) {
  var e = AmountExpression.empty;
  for (final k in keys.split('')) {
    if ('+-*/'.contains(k)) {
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.reset();
  });

  test('a draft survives the page being thrown away', () async {
    final draft = CheckoutDraftController.instance
      ..setExpression(type('20*2+90'))
      ..setLineNames({'20 × 2': 'item 1'})
      ..setNote('pay on friday')
      ..addRepair(
        const ReadyOrder(
          id: 'r1',
          customerName: 'Zihadul Islam',
          customerPhone: '+8801711000000',
          deviceModel: 'vivp',
          price: 500,
        ),
      );

    // Give the debounced write a turn of the event loop.
    await Future<void>.delayed(Duration.zero);

    final restored = CheckoutDraftController();
    await restored.restore();

    expect(restored.expression.input, draft.expression.input);
    expect(restored.note, 'pay on friday');
    expect(restored.namedLines.first.name, 'item 1');
    expect(restored.repairs['r1']?.customerName, 'Zihadul Islam');
    expect(restored.repairs['r1']?.customerPhone, '+8801711000000');
    expect(restored.totalQuantity, 22); // 20 units + 90 + one repair
  });

  test('combined lines list repairs before keypad terms', () {
    final draft = CheckoutDraftController.instance
      ..addRepair(
        const ReadyOrder(
          id: 'r1',
          customerName: 'Zihadul Islam',
          deviceModel: 'vivp',
          price: 500,
        ),
      )
      ..setExpression(type('90+120'));

    expect(draft.combinedLines.map((l) => l.name).toList(), [
      'vivp repair',
      '',
      '',
    ]);

    // Index 1 is the first keypad term, matching the review screen's rows.
    draft.removeLineAt(1);
    expect(draft.expression.input, '120');
    expect(draft.repairs.length, 1);
  });

  test('clearing empties storage as well as memory', () async {
    final draft = CheckoutDraftController.instance
      ..setExpression(type('450'))
      ..setNote('note');
    await Future<void>.delayed(Duration.zero);

    draft.clear();
    await Future<void>.delayed(Duration.zero);

    final restored = CheckoutDraftController();
    await restored.restore();
    expect(restored.isEmpty, isTrue);
    expect(restored.note, isEmpty);
  });
}
