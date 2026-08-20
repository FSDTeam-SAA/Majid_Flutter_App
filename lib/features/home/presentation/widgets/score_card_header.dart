import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';

class ScoreCardHeader extends StatelessWidget {
  final String title;
  final String infoMessage;

  const ScoreCardHeader({
    super.key,
    required this.title,
    required this.infoMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 20),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: Text(
                title,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              content: Text(
                infoMessage,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text('OK', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          child: Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ],
    );
  }
}
