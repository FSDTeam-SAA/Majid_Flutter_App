import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../controller/home_controller.dart';

class AiInsightsCard extends StatelessWidget {
  const AiInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();

    return Obx(() {
      final insights = _generateInsights(homeCtrl);

      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'AI Insights',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.isDark
                        ? Color(0xFF1A2C40)
                        : Color(0xFFE8F1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: Color(0xFF2E76C4),
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    insights,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  width: i == 0 ? 16 : 6,
                  height: 6,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == 0 ? AppColors.primary : AppColors.fieldBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  String _generateInsights(HomeController ctrl) {
    final inventory = ctrl.totalInventoryItems.value;
    final sold = ctrl.totalSoldProducts.value;
    final repairs = ctrl.totalRepairRequests.value;
    final categories = ctrl.totalCategories.value;

    if (inventory == 0 && sold == 0) {
      return 'Get started by adding products to your inventory. Use the Stock tab to add your first device!';
    }

    if (sold > 0 && inventory > 0) {
      final sellRate = (sold / (sold + inventory) * 100).toInt();
      if (sellRate > 50) {
        return 'Great performance! You\'ve sold $sellRate% of your stock. Consider restocking popular items to maintain momentum.';
      }
      return 'You have $inventory items in stock and $sold sold. Focus on marketing your existing inventory to boost sales.';
    }

    if (repairs > 0 && inventory > 0) {
      return 'You have $repairs repair requests and $inventory items across $categories categories. Keep your inventory diverse to attract more customers!';
    }

    return 'You have $inventory items in your inventory across $categories categories. Start selling to see detailed insights here!';
  }
}
