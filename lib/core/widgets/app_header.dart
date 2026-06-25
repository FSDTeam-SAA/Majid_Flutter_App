import 'package:flutter/material.dart';

import '../utils/colors.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Color? buttonBackgroundColor;
  final Color? buttonBorderColor;
  final Color? iconColor;
  final Color? textColor;
  final bool showBackButton;

  const AppHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.buttonBackgroundColor,
    this.buttonBorderColor,
    this.iconColor,
    this.textColor,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: buttonBackgroundColor ?? AppColors.cardBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: buttonBorderColor ?? AppColors.fieldBorder,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: iconColor ?? AppColors.textPrimary,
                  size: 16,
                ),
              ),
            )
          else
            SizedBox(width: 40),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor ?? AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          trailing ?? SizedBox(width: 40),
        ],
      ),
    );
  }
}
