import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onAddRepair;
  final VoidCallback onCreateInvoice;
  final VoidCallback onAddItem;

  const QuickActions({super.key, required this.onAddRepair, required this.onCreateInvoice, required this.onAddItem});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionBtn(label: 'Add Repair', icon: Icons.build_outlined, onTap: onAddRepair),
            const SizedBox(width: 12),
            _ActionBtn(label: 'Create Invoice', icon: Icons.note_add_outlined, onTap: onCreateInvoice),
            const SizedBox(width: 12),
            _ActionBtn(label: 'Add Item', icon: Icons.shopping_bag_outlined, onTap: onAddItem),
          ],
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              // padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Center(child: Icon(icon, color: AppColors.primary, size: 26)),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w400, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
