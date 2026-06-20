import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_card.dart';

class AiRiskCard extends StatelessWidget {
  final double percentage;
  final String description;

  const AiRiskCard({
    super.key,
    required this.percentage,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI Risk Lavel',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: const Color(0xFF1E2E2A),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
