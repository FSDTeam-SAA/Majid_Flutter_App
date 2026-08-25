import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../utils/status_helper.dart';
import 'status_badge.dart';

class InfoField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool? isStatus;

  const InfoField({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.isStatus,
  });

  @override
  Widget build(BuildContext context) {
    final showAsStatus = isStatus ?? StatusHelper.isStatusField(label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        if (showAsStatus && value.trim().isNotEmpty && value.trim() != 'N/A')
          StatusBadge(label: value, fieldLabel: label, color: valueColor)
        else
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
