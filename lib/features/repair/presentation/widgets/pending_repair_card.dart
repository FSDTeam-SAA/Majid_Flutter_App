import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../controller/repair_data.dart';

class PendingRepairCard extends StatelessWidget {
  final RepairItem item;
  final bool isNudging;
  final VoidCallback onNudge;
  final VoidCallback? onTap;

  const PendingRepairCard({
    super.key,
    required this.item,
    required this.onNudge,
    this.isNudging = false,
    this.onTap,
  });

  String get _technicianName {
    final name = item.technicianName.trim();
    return name.isEmpty ? 'Unassigned' : name;
  }

  @override
  Widget build(BuildContext context) {
    final hasTechnician = _technicianName != 'Unassigned';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE8920A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hourglass_bottom_rounded,
                color: Color(0xFFE8920A),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.name} • ${item.brand}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        hasTechnician
                            ? Icons.person_outline
                            : Icons.person_off_outlined,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _technicianName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(label: item.status, isUppercase: false),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: (isNudging || !hasTechnician) ? null : onNudge,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: isNudging
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Nudge',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
