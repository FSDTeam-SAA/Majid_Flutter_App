import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../controller/invoice_data.dart';

class InvoiceProductItem extends StatelessWidget {
  final InvoiceProduct product;
  final bool isSelected;
  final VoidCallback onTap;

  const InvoiceProductItem({super.key, required this.product, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111A24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A2840)),
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.textSecondary, width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.black, size: 15) : null,
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 52, height: 52,
                color: product.color.withValues(alpha: 0.3),
                child: Icon(Icons.smartphone, color: product.color, size: 28),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(product.code, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '£${product.price.toStringAsFixed(2)}',
              style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
