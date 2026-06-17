import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class AiInsightsCard extends StatelessWidget {
  const AiInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.fieldBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('AI Insights', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFF1A2C40), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.bar_chart, color: Color(0xFF5B9FD4), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('iPhone 15 Pro sales increased by 42% this month. Consider increasing stock!', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
            ),
          ]),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              width: i == 0 ? 16 : 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(color: i == 0 ? AppColors.primary : AppColors.fieldBorder, borderRadius: BorderRadius.circular(3)),
            )),
          ),
        ],
      ),
    );
  }
}
