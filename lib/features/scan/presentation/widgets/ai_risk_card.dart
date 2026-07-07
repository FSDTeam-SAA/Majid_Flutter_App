import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_card.dart';

class AiRiskCard extends StatelessWidget {
  final double percentage;
  final String description;
  final String riskLabel;

  const AiRiskCard({
    super.key,
    required this.percentage,
    required this.description,
    this.riskLabel = '',
  });

  Color get _riskColor {
    final label = riskLabel.toLowerCase();
    if (label.contains('low')) return const Color(0xFF22C55E);
    if (label.contains('medium') || label.contains('moderate')) return const Color(0xFFF59E0B);
    if (label.contains('high')) return const Color(0xFFEF4444);

    if (percentage >= 0.8) return const Color(0xFF22C55E);
    if (percentage >= 0.5) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor;

    return AppCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Risk Level:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              if (riskLabel.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    riskLabel.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          Center(
            child: Text(
              'Risk Score: ${(percentage * 100).toInt()}/100',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 6,
              backgroundColor: AppColors.fieldBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
