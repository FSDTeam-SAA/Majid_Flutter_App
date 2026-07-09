import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../domain/entities/supplier.dart';

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback? onDelete;

  const SupplierCard({super.key, required this.supplier, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final statusColor = supplier.isActive ? const Color(0xFF34C759) : AppColors.textSecondary;
    final initial = supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Text(
                  initial,
                  style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: statusColor, size: 8),
                        const SizedBox(width: 5),
                        Text(
                          supplier.isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 20),
                ),
            ],
          ),
          if (supplier.email.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.mail_outline_rounded, supplier.email),
          ],
          if (supplier.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.call_outlined, supplier.phone),
          ],
          if (supplier.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, supplier.address),
          ],
          if (supplier.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.fieldBorder, height: 1),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.sticky_note_2_outlined, supplier.notes),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
