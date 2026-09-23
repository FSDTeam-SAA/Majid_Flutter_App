/// One line of a hand-keyed calculation, e.g. `980 x 5` meaning five units at
/// 980 each.
class CalculationLine {
  /// The keyed term, shown as the shopkeeper typed it.
  final String expression;

  /// Units this line represents: `980 x 5` is 5, a bare `980` is 1.
  final int quantity;

  /// What the line adds to the total.
  final double amount;

  /// Filled in on the Calculation Note screen.
  final String name;

  const CalculationLine({
    required this.expression,
    required this.quantity,
    required this.amount,
    this.name = '',
  });

  CalculationLine copyWith({String? name}) => CalculationLine(
    expression: expression,
    quantity: quantity,
    amount: amount,
    name: name ?? this.name,
  );
}
