import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Calculator keypad: round digit keys on a recessed tray, with the arithmetic
/// operators stacked on a single red rail down the right hand side.
class CheckoutKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onPercent;
  final ValueChanged<String> onOperator;
  final VoidCallback onBackspace;

  /// Operator currently waiting for its right hand operand, if any.
  final String? activeOperator;

  const CheckoutKeypad({
    super.key,
    required this.onDigit,
    required this.onDecimal,
    required this.onPercent,
    required this.onOperator,
    required this.onBackspace,
    this.activeOperator,
  });

  static const _railWidth = 66.0;
  static const _gap = 10.0;
  static const _padding = 14.0;

  /// Cells are wider than they are tall, so the round keys shrink vertically
  /// and the whole tray takes less height.
  static const _cellAspect = 1.34;
  static const _digits = ['7', '8', '9', '4', '5', '6', '1', '2', '3', '0'];

  /// Operator symbol paired with its icon; `/` has no rounded Material icon so
  /// it falls back to a drawn glyph.
  static const List<(String, IconData?)> operators = [
    ('+', Icons.add_rounded),
    ('-', Icons.remove_rounded),
    ('*', Icons.close_rounded),
    ('/', null),
    ('%', Icons.percent_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inner = constraints.maxWidth - _padding * 2;
        final gridWidth = inner - _railWidth - _gap;
        final cell = (gridWidth - _gap * 2) / 3 / _cellAspect;
        final gridHeight = cell * 4 + _gap * 3;

        // Opaque tray, so no BackdropFilter: the blur it used to run was
        // invisible behind a solid colour and cost a layer every frame.
        return Container(
          padding: const EdgeInsets.fromLTRB(
            _padding,
            _padding,
            _padding,
            _padding + 6,
          ),
          color: CheckoutTokens.keypadPanel,
          child: SizedBox(
            height: gridHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: gridWidth,
                  child: GridView.count(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: _gap,
                    crossAxisSpacing: _gap,
                    childAspectRatio: _cellAspect,
                    children: [
                      for (final digit in _digits)
                        _KeypadKey(label: digit, onTap: () => onDigit(digit)),
                      _KeypadKey(label: '.', textSize: 28, onTap: onDecimal),
                      _KeypadKey(
                        icon: Icons.backspace_outlined,
                        onTap: onBackspace,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: _gap),
                Expanded(
                  child: _OperatorRail(
                    activeOperator: activeOperator,
                    onOperator: onOperator,
                    onPercent: onPercent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Single red column holding the arithmetic operators.
class _OperatorRail extends StatelessWidget {
  final String? activeOperator;
  final ValueChanged<String> onOperator;
  final VoidCallback onPercent;

  const _OperatorRail({
    required this.activeOperator,
    required this.onOperator,
    required this.onPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: CheckoutTokens.operatorGradient,
        borderRadius: BorderRadius.circular(50),
        boxShadow: CheckoutTokens.glow(
          CheckoutTokens.operatorColor,
          blur: 12,
          y: 5,
          opacity: 0.5,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < CheckoutKeypad.operators.length; index++)
            Expanded(
              child: Column(
                children: [
                  if (index > 0)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  Expanded(
                    child: _OperatorKey(
                      icon: CheckoutKeypad.operators[index].$2,
                      isActive:
                          activeOperator == CheckoutKeypad.operators[index].$1,
                      onTap: () {
                        final symbol = CheckoutKeypad.operators[index].$1;
                        if (symbol == '%') {
                          onPercent();
                        } else {
                          onOperator(symbol);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OperatorKey extends StatelessWidget {
  final IconData? icon;
  final bool isActive;
  final VoidCallback onTap;

  const _OperatorKey({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      builder: (isPressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.26)
              : (isPressed ? Colors.white.withValues(alpha: 0.16) : null),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: icon == null
              ? Text(
                  '÷',
                  style: CheckoutTokens.text(
                    size: 25,
                    weight: FontWeight.w600,
                    color: Colors.white,
                    height: 1,
                  ),
                )
              : Icon(icon, size: 21, color: Colors.white),
        ),
      ),
    );
  }
}

/// Wraps a key so it dips slightly while pressed.
class _Pressable extends StatefulWidget {
  final Widget Function(bool isPressed) builder;
  final VoidCallback onTap;

  const _Pressable({required this.builder, required this.onTap});

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
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
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.builder(_isPressed),
      ),
    );
  }
}

class _KeypadKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final double textSize;

  const _KeypadKey({
    this.label,
    this.icon,
    required this.onTap,
    this.textSize = 27,
  });

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      builder: (isPressed) => Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 110),
            decoration: BoxDecoration(
              color: isPressed
                  ? CheckoutTokens.accentSoft
                  : CheckoutTokens.keyFill,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon != null
                  ? Icon(icon, size: 22, color: CheckoutTokens.keyLabel)
                  : Text(
                      label ?? '',
                      style: CheckoutTokens.text(
                        size: textSize,
                        weight: FontWeight.w400,
                        color: CheckoutTokens.keyLabel,
                        letterSpacing: -0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
