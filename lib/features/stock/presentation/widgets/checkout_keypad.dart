import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Calculator keypad built to the client's mockup: three digit columns with the
/// operators in a fourth, each operator carrying its own lime line out to the
/// right edge of the screen.
class CheckoutKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final ValueChanged<String> onOperator;
  final VoidCallback onBackspace;

  /// Operator waiting for its right hand operand, highlighted while pending.
  final String? activeOperator;

  const CheckoutKeypad({
    super.key,
    required this.onDigit,
    required this.onDecimal,
    required this.onOperator,
    required this.onBackspace,
    this.activeOperator,
  });

  static const _gap = 10.0;
  static const _sidePad = 18.0;

  /// The lime line runs from the operator key into this trailing strip.
  static const _lineWidth = 26.0;

  /// Apple's minimum comfortable target; the client asked for 48 x 48.
  static const _minKeyHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final usable = constraints.maxWidth - _sidePad - _lineWidth - _gap * 3;
        final cell = usable / 4;
        final keyHeight = (cell / 1.18).clamp(_minKeyHeight, 84.0);

        return Padding(
          padding: const EdgeInsets.only(left: _sidePad),
          child: Column(
            children: [
              _row(['7', '8', '9'], '+', cell, keyHeight),
              const SizedBox(height: _gap),
              _row(['4', '5', '6'], '-', cell, keyHeight),
              const SizedBox(height: _gap),
              _row(['1', '2', '3'], '*', cell, keyHeight),
              const SizedBox(height: _gap),
              _row(['0', '.', 'back'], '/', cell, keyHeight),
            ],
          ),
        );
      },
    );
  }

  Widget _row(List<String> keys, String operator, double cell, double height) {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          for (final key in keys) ...[
            SizedBox(width: cell, child: _digitKey(key)),
            const SizedBox(width: _gap),
          ],
          SizedBox(
            width: cell,
            child: _OperatorKey(
              symbol: operator,
              isActive: activeOperator == operator,
              onTap: () => onOperator(operator),
            ),
          ),
          // Each operator gets its own line to the edge - no circles and no
          // vertical connections between rows, as specified.
          SizedBox(
            width: _lineWidth,
            child: Center(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: CheckoutTokens.limeInk.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _digitKey(String key) {
    if (key == 'back') {
      return _KeypadKey(
        onTap: onBackspace,
        child: Icon(
          Icons.backspace_outlined,
          size: 22,
          color: CheckoutTokens.danger,
        ),
      );
    }
    return _KeypadKey(
      onTap: key == '.' ? onDecimal : () => onDigit(key),
      child: Text(
        key,
        style: CheckoutTokens.text(
          size: key == '.' ? 30 : 26,
          weight: FontWeight.w600,
          color: CheckoutTokens.strongText,
        ),
      ),
    );
  }
}

/// White key with a pressed state.
class _KeypadKey extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color? background;
  final Color? border;

  const _KeypadKey({
    required this.child,
    required this.onTap,
    this.background,
    this.border,
  });

  @override
  State<_KeypadKey> createState() => _KeypadKeyState();
}

class _KeypadKeyState extends State<_KeypadKey> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed
              ? CheckoutTokens.limeSoft
              : (widget.background ?? CheckoutTokens.keySurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isPressed
                ? CheckoutTokens.limeInk.withValues(alpha: 0.5)
                : (widget.border ?? CheckoutTokens.keyEdge),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// `+` and `x` are the ones shopkeepers reach for, so they carry a pale lime
/// face and a heavier glyph.
class _OperatorKey extends StatelessWidget {
  final String symbol;
  final bool isActive;
  final VoidCallback onTap;

  const _OperatorKey({
    required this.symbol,
    required this.isActive,
    required this.onTap,
  });

  static const _emphasised = {'+', '*'};

  @override
  Widget build(BuildContext context) {
    final isEmphasised = _emphasised.contains(symbol);
    final tint = isEmphasised || isActive
        ? CheckoutTokens.limeInk
        : CheckoutTokens.strongText;

    return _KeypadKey(
      onTap: onTap,
      background: isEmphasised || isActive
          ? CheckoutTokens.limeSoft
          : CheckoutTokens.keySurface,
      border: isEmphasised || isActive
          ? CheckoutTokens.limeInk.withValues(alpha: 0.38)
          : CheckoutTokens.keyEdge,
      child: _glyph(tint, isEmphasised),
    );
  }

  Widget _glyph(Color color, bool isEmphasised) {
    final size = isEmphasised ? 30.0 : 26.0;
    final weight = isEmphasised ? FontWeight.w700 : FontWeight.w500;

    return switch (symbol) {
      '+' => Icon(Icons.add_rounded, size: size, color: color),
      '-' => Icon(Icons.remove_rounded, size: size, color: color),
      '*' => Icon(Icons.close_rounded, size: size, color: color),
      _ => Text(
        '÷',
        style: CheckoutTokens.text(size: size, weight: weight, color: color),
      ),
    };
  }
}
