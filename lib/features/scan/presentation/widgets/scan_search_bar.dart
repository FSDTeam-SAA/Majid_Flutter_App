import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class ScanSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const ScanSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          SizedBox(width: 16),
          Icon(Icons.search, color: AppColors.textSecondary, size: 22),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter IMEI / Serial Number',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(6),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: Colors.black,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
