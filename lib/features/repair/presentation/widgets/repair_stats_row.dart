import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class RepairStatsRow extends StatelessWidget {
  const RepairStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildCard(Icons.build_rounded, const Color(0xFF1A2A6C), const Color(0xFF5B8DEF), '27', 'In Progress')),
        const SizedBox(width: 10),
        Expanded(child: _buildCard(Icons.check_circle_outline_rounded, const Color(0xFF0D2A1A), AppColors.primary, '10', 'Completed')),
        const SizedBox(width: 10),
        Expanded(child: _buildCard(Icons.bar_chart_rounded, const Color(0xFF0D2A1A), AppColors.primary, '£14,650', 'Total Sales')),
      ],
    );
  }

  Widget _buildCard(IconData icon, Color iconBg, Color iconColor, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2840)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
