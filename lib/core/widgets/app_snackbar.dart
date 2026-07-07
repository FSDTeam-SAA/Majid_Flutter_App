import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/colors.dart';

void showErrorSnackbar(String message) {
  _showAppSnackbar(
    title: 'Error',
    message: message,
    accentColor: AppColors.dangerColor,
    backgroundColor: AppColors.errorBackground,
    borderColor: AppColors.errorBorder,
    icon: Icons.error_outline_rounded,
  );
}

void showSuccessSnackbar(String message) {
  _showAppSnackbar(
    title: 'Success',
    message: message,
    accentColor: AppColors.primary,
    backgroundColor: AppColors.successBackground,
    borderColor: AppColors.successBorder,
    icon: Icons.check_circle_outline_rounded,
    duration: const Duration(seconds: 2),
  );
}

void _showAppSnackbar({
  required String title,
  required String message,
  required Color accentColor,
  required Color backgroundColor,
  required Color borderColor,
  required IconData icon,
  Duration duration = const Duration(seconds: 3),
}) {
  if (Get.isSnackbarOpen) {
    Get.closeCurrentSnackbar();
  }

  Get.snackbar(
    '',
    '',
    titleText: Text(
      title,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        height: 1.35,
      ),
    ),
    icon: Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: AppColors.isDark ? 0.18 : 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: accentColor, size: 22),
    ),
    shouldIconPulse: false,
    snackStyle: SnackStyle.FLOATING,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: backgroundColor,
    borderRadius: 18,
    borderWidth: 1.1,
    borderColor: borderColor,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
    boxShadows: [
      BoxShadow(
        color: AppColors.overlayShadow,
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
    duration: duration,
  );
}
