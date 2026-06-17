import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class ProfileMenuItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const ProfileMenuItem({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x8012161D),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF232A36)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15))),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
