import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../controller/repair_data.dart';

class CheckoutProductItem extends StatelessWidget {
  final CheckoutProduct product;

  const CheckoutProductItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final color = Color(product.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1A2840))),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 64,
              height: 64,
              color: color.withValues(alpha: 0.2),
              child: Icon(Icons.smartphone, color: color, size: 34),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.code,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0D2A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '£${product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
