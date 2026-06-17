import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/colors.dart';

void showErrorSnackbar(String message) {
  Get.snackbar(
    'Error',
    message,
    backgroundColor: const Color(0xFF2A1010),
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
    duration: const Duration(seconds: 3),
  );
}

void showSuccessSnackbar(String message) {
  Get.snackbar(
    'Success',
    message,
    backgroundColor: const Color(0xFF0D2A1A),
    colorText: AppColors.primary,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
    duration: const Duration(seconds: 2),
  );
}
