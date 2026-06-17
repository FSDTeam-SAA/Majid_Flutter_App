import 'package:flutter/material.dart';
import '../../../../core/widgets/info_field.dart';

class DeviceFieldFull extends StatelessWidget {
  final String label;
  final String value;

  const DeviceFieldFull({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2840)),
      ),
      child: InfoField(label: label, value: value),
    );
  }
}

class DeviceFieldRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final Color? leftValueColor;
  final Color? rightValueColor;

  const DeviceFieldRow({
    super.key,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.leftValueColor,
    this.rightValueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCard(leftLabel, leftValue, leftValueColor)),
        const SizedBox(width: 10),
        Expanded(child: _buildCard(rightLabel, rightValue, rightValueColor)),
      ],
    );
  }

  Widget _buildCard(String label, String value, Color? valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2840)),
      ),
      child: InfoField(label: label, value: value, valueColor: valueColor),
    );
  }
}
