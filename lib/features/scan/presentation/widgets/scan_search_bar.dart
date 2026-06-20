import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class ScanSearchBar extends StatelessWidget {
  final TextEditingController controller;

  const ScanSearchBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              decoration: const InputDecoration(
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
            margin: const EdgeInsets.all(6),
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
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
