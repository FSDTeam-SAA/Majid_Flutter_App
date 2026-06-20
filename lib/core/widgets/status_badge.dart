import 'package:flutter/material.dart';
import '../utils/colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? _colorForStatus(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Color _colorForStatus(String status) {
    return switch (status) {
      'Clean' || 'Completed' => AppColors.primary,
      'Blacklisted' => const Color(0xFFFF4444),
      'Active' || 'In Progress' => const Color(0xFF4DB8FF),
      _ => const Color(0xFF7A8A85),
    };
  }
}
