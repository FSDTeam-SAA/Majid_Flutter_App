/// One line of a hand-keyed calculation, e.g. `20 x 2` meaning 20 units at 90.
class CalculationLine {
  /// The keyed term, shown as the shopkeeper typed it.
  final String expression;

  /// Units this line represents: `20 x 2` is 20, a bare `90` is 1.
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
