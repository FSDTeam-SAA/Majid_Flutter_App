import 'package:flutter/material.dart';
import '../utils/status_helper.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final String? fieldLabel;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isUppercase;

  const StatusBadge({
    super.key,
    required this.label,
    this.fieldLabel,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.isUppercase = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = StatusHelper.getStyle(label, fieldLabel: fieldLabel);
    final txtColor = color ?? style.textColor;
    final bgColor = backgroundColor ?? style.backgroundColor;
    final brdColor = borderColor ?? style.borderColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: brdColor, width: 1),
      ),
      child: Text(
        isUppercase ? label.toUpperCase() : label,
        style: TextStyle(
          color: txtColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
