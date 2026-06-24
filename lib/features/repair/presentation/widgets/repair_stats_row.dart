import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class RepairStatsRow extends StatelessWidget {
  final int inProgress;
  final int completed;
  final double totalSales;

  const RepairStatsRow({
    super.key,
    this.inProgress = 0,
    this.completed = 0,
    this.totalSales = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            Icons.build_rounded,
            Color(0xFF1A2A6C),
            Color(0xFF5B8DEF),
            '$inProgress',
            'In Progress',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildCard(
            Icons.check_circle_outline_rounded,
            AppColors.fieldBackground,
            AppColors.primary,
            '$completed',
            'Completed',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildCard(
            Icons.bar_chart_rounded,
            AppColors.fieldBackground,
            AppColors.primary,
            _formatCurrency(totalSales),
            'Total Sales',
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000) {
      return '£${(value / 1000).toStringAsFixed(1)}k';
    }
    return '£${value.toStringAsFixed(0)}';
  }

  Widget _buildCard(
    IconData icon,
    Color iconBg,
    Color iconColor,
    String value,
    String label,
  ) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
