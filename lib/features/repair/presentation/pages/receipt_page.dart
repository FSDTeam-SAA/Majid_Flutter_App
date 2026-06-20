import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_outlined_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../widgets/dashed_divider.dart';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Receipt'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildVerifiedIcon(),
                  const SizedBox(height: 16),
                  const Text(
                    'Receipt Verified',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetails(),
                  const SizedBox(height: 20),
                  _buildQrCode(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            child: AppOutlinedButton(
              label: 'Get PDF Receipt',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF receipt export is coming soon.'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.15),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: const Icon(
        Icons.check_circle_rounded,
        color: AppColors.primary,
        size: 42,
      ),
    );
  }

  Widget _buildDetails() {
    final rows = [
      ('Order ID', '000085752257'),
      ('Date', 'Mar 22, 2023'),
      ('Time', '07:80 AM'),
      ('Shop Name', 'Your Shop'),
      ('Price', '£899.00'),
    ];

    return Column(
      children: rows.asMap().entries.map((e) {
        final isFirst = e.key == 0;
        final isLast = e.key == rows.length - 1;
        return Column(
          children: [
            if (isFirst)
              const Divider(color: Color(0xFF1E2E2A), height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.value.$1,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    e.value.$2,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight:
                          e.value.$1 == 'Shop Name' || e.value.$1 == 'Price'
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              const DashedDivider()
            else
              const Divider(color: Color(0xFF1E2E2A), height: 1, thickness: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQrCode() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/qrcode.jpg',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
