import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/colors.dart';

void showErrorSnackbar(String message) {
  Get.snackbar(
    'Error',
    message,
    backgroundColor: AppColors.errorBackground,
    colorText: AppColors.textPrimary,
    snackPosition: SnackPosition.BOTTOM,
    margin: EdgeInsets.all(16),
    borderRadius: 12,
    duration: Duration(seconds: 3),
  );
}

void showSuccessSnackbar(String message) {
  Get.snackbar(
    'Success',
    message,
    backgroundColor: AppColors.successBackground,
    colorText: AppColors.primary,
    snackPosition: SnackPosition.BOTTOM,
    margin: EdgeInsets.all(16),
    borderRadius: 12,
    duration: Duration(seconds: 2),
  );
}
