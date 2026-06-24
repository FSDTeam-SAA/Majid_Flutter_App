import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class InvoiceInputField extends StatelessWidget {
  final String hint;

  const InvoiceInputField({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
      child: TextField(
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
