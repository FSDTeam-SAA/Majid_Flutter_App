import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../controller/invoice_data.dart';

class InvoiceProductItem extends StatelessWidget {
  final InvoiceProduct product;
  final bool isSelected;
  final VoidCallback onTap;

  const InvoiceProductItem({
    super.key,
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.isDark
              ? AppColors.cardBackground
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.isDark
                ? AppColors.fieldBorder
                : const Color(0xFFE4E7EC),
          ),
          boxShadow: AppColors.isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF6BA0C8).withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: AppColors.surfaceForeground,
                      size: 15,
                    )
                  : null,
            ),
            SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 52,
                height: 52,
                color: product.color.withValues(alpha: 0.3),
                child: Icon(Icons.smartphone, color: product.color, size: 28),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    product.code,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (product.imeiSerial.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      'IMEI/Serial: ${product.imeiSerial}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${Get.find<ProfileController>().currencySymbol}${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
