import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../controller/repair_data.dart';

class TimelineWidget extends StatelessWidget {
  final List<TimelineStep> steps;

  const TimelineWidget({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((e) => _buildStep(e.value, e.key == steps.length - 1)),
        ],
      ),
    );
  }

  Widget _buildStep(TimelineStep step, bool isLast) {
    Widget icon;
    if (step.status == TimelineStatus.done) {
      icon = Container(
        width: 36, height: 36,
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.check, color: Colors.black, size: 18),
      );
    } else if (step.status == TimelineStatus.inProgress) {
      icon = Container(
        width: 36, height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4DB8FF), width: 3), color: const Color(0xFF0D1F2D)),
        child: const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF4DB8FF)))),
      );
    } else {
      icon = Container(
        width: 36, height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF2A3A4A)), color: const Color(0xFF0B1520)),
        child: const Icon(Icons.access_time_rounded, color: Color(0xFF3A4A5A), size: 18),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              icon,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: step.status == TimelineStatus.done ? AppColors.primary.withValues(alpha: 0.4) : const Color(0xFF1A2840),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      Text(step.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  if (step.status == TimelineStatus.pending)
                    const Text('Pending', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
