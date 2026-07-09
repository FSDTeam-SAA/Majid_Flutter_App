import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/animation/app_entrance.dart';
import '../../../../core/animation/pressable_scale.dart';
import '../../../../core/utils/colors.dart';
import '../controller/home_controller.dart';

class TopProductsList extends StatelessWidget {
  const TopProductsList({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();

    return Obx(() {
      final products = homeCtrl.soldProducts;
      final previewProducts = products.take(4).toList();

      return Column(
        children: [
          Row(
            children: [
              Text(
                'Top Selling Products',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              PressableScale(
                enabled: products.isNotEmpty,
                pressedScale: 0.98,
                child: InkWell(
                  onTap: products.isEmpty
                      ? null
                      : () => _showAllProductsSheet(context, products),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: products.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (products.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.textSecondary,
                    size: 36,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No sold products yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(previewProducts.length, (i) {
              final item = previewProducts[i];
              return _buildProductRow(
                item: item,
                rank: i + 1,
                maxSold: _asNumber(products[0]['quantity']) ?? 1,
              ).entrance(index: i, begin: const Offset(0, 0.05));
            }),
        ],
      );
    });
  }

  Future<void> _showAllProductsSheet(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) {
    final maxSold = _asNumber(products[0]['quantity']) ?? 1;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'All Sold Products',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: products.length,
                    itemBuilder: (context, index) => _buildProductRow(
                      item: products[index],
                      rank: index + 1,
                      maxSold: maxSold,
                    ).entrance(index: index, begin: const Offset(0, 0.045)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductRow({
    required Map<String, dynamic> item,
    required int rank,
    required num maxSold,
  }) {
    final name =
        item['productName'] ?? item['itemName'] ?? item['brand'] ?? 'Unknown';
    final sold = _asNumber(item['quantity']) ?? 1;
    final progress = maxSold > 0 ? sold / maxSold : 0.0;
    final price =
        _asNumber(item['expectedPrice']) ??
        _asNumber(item['sellingPrice']) ??
        _asNumber(item['purchasePrice']);

    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.phone_iphone,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.toDouble(),
                    backgroundColor: AppColors.fieldBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price == null
                    ? sold.toStringAsFixed(0)
                    : '£${price.toStringAsFixed(0)}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                price == null ? 'Sold' : 'Price',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  num? _asNumber(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
