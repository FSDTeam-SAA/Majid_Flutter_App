import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class InvoiceInputField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final bool readOnly;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const InvoiceInputField({
    super.key,
    required this.hint,
    this.controller,
    this.readOnly = false,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: AppColors.isDark ? 0.6 : 0.72,
          ),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}
