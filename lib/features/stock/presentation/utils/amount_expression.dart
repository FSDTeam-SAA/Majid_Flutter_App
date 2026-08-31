/// Immutable calculator input for the checkout keypad.
///
/// Holds the raw keystrokes (e.g. `450.2+24.12-10%`) and evaluates them with
/// normal operator precedence. Percent follows the behaviour shopkeepers expect
/// from a POS terminal:
///
/// * `500 - 10%` -> `450`  (10% discount off the running total)
/// * `500 + 10%` -> `550`  (10% VAT added on top)
/// * `500 x 10%` -> `50`   (10% of 500)
/// * `10%`       -> `0.1`  (bare percentage)
class AmountExpression {
  final String input;

  const AmountExpression._(this.input);

  static const AmountExpression empty = AmountExpression._('0');

  factory AmountExpression.fromValue(num value) {
    final rounded = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return AmountExpression._(rounded);
  }

  static const _operators = {'+', '-', '*', '/'};
  static const _operatorGlyphs = {'+': '+', '-': '−', '*': '×', '/': '÷'};

  static bool _isOperator(String value) => _operators.contains(value);

  bool get isEmpty => input == '0';

  /// True once the expression holds more than a single number.
  bool get hasOperation =>
      input.contains('%') ||
      input.substring(1).split('').any(_isOperator) ||
      input.endsWith('%');

  String get _lastChar => input.isEmpty ? '' : input[input.length - 1];

  /// Operator still waiting for its right hand operand, so the keypad can
  /// highlight it.
  String? get pendingOperator => _isOperator(_lastChar) ? _lastChar : null;

  /// The number currently being typed, without its percent marker.
  String get _currentSegment {
    for (var i = input.length - 1; i >= 0; i--) {
      if (_isOperator(input[i])) return input.substring(i + 1);
    }
    return input;
  }

  AmountExpression addDigit(String digit) {
    if (_lastChar == '%') return this;
    if (input == '0') return AmountExpression._(digit);
    if (_currentSegment == '0') {
      return AmountExpression._(
        '${input.substring(0, input.length - 1)}$digit',
      );
    }
    if (_currentSegment.length >= 10) return this;
    return AmountExpression._('$input$digit');
  }

  AmountExpression addDecimal() {
    if (_lastChar == '%') return this;
    final segment = _currentSegment;
    if (segment.contains('.')) return this;
    if (segment.isEmpty) return AmountExpression._('${input}0.');
    return AmountExpression._('$input.');
  }

  AmountExpression addOperator(String operator) {
    if (!_isOperator(operator)) return this;

    var next = input;
    if (next.endsWith('.')) next = next.substring(0, next.length - 1);
    if (next.isEmpty) return this;
    if (_isOperator(next[next.length - 1])) {
      next = next.substring(0, next.length - 1);
    }
    return AmountExpression._('$next$operator');
  }

  AmountExpression addPercent() {
    if (_lastChar == '%' || input.isEmpty) return this;
    if (_isOperator(_lastChar) || _lastChar == '.') return this;
    return AmountExpression._('$input%');
  }

  AmountExpression backspace() {
    if (input.length <= 1) return empty;
    return AmountExpression._(input.substring(0, input.length - 1));
  }

  AmountExpression cleared() => empty;

  /// Result of the expression, or `null` when it cannot be resolved
  /// (currently only division by zero).
  double? get value {
    final values = <double>[];
    final ops = <String>[];

    for (final token in _tokenize()) {
      if (_isOperator(token)) {
        ops.add(token);
        continue;
      }
      if (token.isEmpty) continue;

      var raw = token;
      final isPercent = raw.endsWith('%');
      if (isPercent) raw = raw.substring(0, raw.length - 1);

      var number = double.tryParse(raw) ?? 0;
      if (isPercent) {
        final pending = ops.isEmpty ? null : ops.last;
        if (pending == '+' || pending == '-') {
          final base = _reduce(values, ops.sublist(0, ops.length - 1)) ?? 0;
          number = base * number / 100;
        } else {
          number = number / 100;
        }
      }
      values.add(number);
    }

    if (values.isEmpty) return 0;
    final trimmed = ops.length >= values.length
        ? ops.sublist(0, values.length - 1)
        : ops;
    return _reduce(values, trimmed);
  }

  List<String> _tokenize() {
    final tokens = <String>[];
    final buffer = StringBuffer();

    for (final char in input.split('')) {
      if (_isOperator(char)) {
        tokens.add(buffer.toString());
        buffer.clear();
        tokens.add(char);
      } else {
        buffer.write(char);
      }
    }
    tokens.add(buffer.toString());
    return tokens;
  }

  static double? _reduce(List<double> values, List<String> ops) {
    if (values.isEmpty) return null;

    final numbers = [...values];
    final operators = [...ops];

    var index = 0;
    while (index < operators.length) {
      final operator = operators[index];
      if (operator == '*' || operator == '/') {
        final right = numbers[index + 1];
        if (operator == '/' && right == 0) return null;
        numbers[index] = operator == '*'
            ? numbers[index] * right
            : numbers[index] / right;
        numbers.removeAt(index + 1);
        operators.removeAt(index);
      } else {
        index++;
      }
    }

    var result = numbers.first;
    for (var i = 0; i < operators.length; i++) {
      result = operators[i] == '+'
          ? result + numbers[i + 1]
          : result - numbers[i + 1];
    }
    return result;
  }

  /// Human readable form of the keystrokes, e.g. `450.2 + 24.12 − 10%`.
  String get display {
    final buffer = StringBuffer();
    for (final char in input.split('')) {
      if (_isOperator(char)) {
        buffer.write(' ${_operatorGlyphs[char]} ');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }
}
