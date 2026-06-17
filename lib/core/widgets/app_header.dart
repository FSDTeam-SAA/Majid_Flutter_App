import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 16),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          trailing ?? const SizedBox(width: 40),
        ],
      ),
    );
  }
}
