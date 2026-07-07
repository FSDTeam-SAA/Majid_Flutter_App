import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class RepairStatsRow extends StatelessWidget {
  static const _iconAssetScale = 1.9;

  final int inProgress;
  final int completed;
  final double totalSales;

  const RepairStatsRow({super.key, this.inProgress = 0, this.completed = 0, this.totalSales = 0});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildCard(
            'assets/icons/inprogress.png',
            '$inProgress',
            'In Progress',
            glowColor: const Color(0xFF3B82F6),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildCard(
            'assets/icons/completed.png',
            '$completed',
            'Completed',
            glowColor: const Color(0xFF6BF36B),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildCard(
            'assets/icons/totalsal.png',
            _formatCurrency(totalSales),
            'Total Sales',
            glowColor: const Color(0xFF6BF36B),
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
    String assetPath,
    String value,
    String label, {
    required Color glowColor,
  }) {
    final valueStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      height: 1.08,
      letterSpacing: -0.35,
    );
    final labelStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0.1,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBadge(assetPath, glowColor: glowColor),
          const SizedBox(height: 16),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: valueStyle),
          const SizedBox(height: 6),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: labelStyle),
        ],
      ),
    );
  }

  Widget _buildIconBadge(
    String assetPath, {
    required Color glowColor,
  }) {
    return Transform.scale(
      scale: _iconAssetScale,
      child: Image.asset(assetPath, fit: BoxFit.cover, height: 36, width: 36),
    );
  }
}
