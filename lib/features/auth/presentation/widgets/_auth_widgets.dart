import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      //onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.fieldBorder),
          borderRadius: BorderRadius.circular(10),
          color: AppColors.fieldBackground,
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 16),
      ),
    );
  }
}

class ImoscanTitle extends StatelessWidget {
  const ImoscanTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Imo',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: 'scan',
            style: TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class AuthLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const AuthLink({super.key, required this.text, required this.linkText, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            TextSpan(
              text: linkText,
              style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
