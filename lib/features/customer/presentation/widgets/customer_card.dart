import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../domain/entities/customer.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CustomerCard({super.key, required this.customer, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final displayName = customer.fullName.isEmpty ? customer.email : customer.fullName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

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
                child: Text(
                  displayName.isEmpty ? 'Customer' : displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                  ),
                ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline_rounded, color: AppColors.dangerColor, size: 18),
                  ),
                ),
            ],
          ),
          if (customer.email.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.mail_outline_rounded, customer.email),
          ],
          if (customer.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.call_outlined, customer.phone),
          ],
          if (customer.address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, customer.address),
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
