import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../controller/home_controller.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();

    return Obx(() => GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _StatCard(
              title: 'Total Items',
              value: '${homeCtrl.totalInventoryItems.value}',
              icon: Icons.inventory_2_outlined,
              iconBg: const Color(0xFF1A3020),
              iconColor: const Color(0xFF2D5C38),
            ),
            _StatCard(
              title: 'Sold Products',
              value: '${homeCtrl.totalSoldProducts.value}',
              icon: Icons.shopping_cart_outlined,
              iconBg: const Color(0xFF1F1A35),
              iconColor: const Color(0xFF3D2F6E),
            ),
            _StatCard(
              title: 'Repair Requests',
              value: '${homeCtrl.totalRepairRequests.value}',
              icon: Icons.build_outlined,
              iconBg: const Color(0xFF182232),
              iconColor: const Color(0xFF1E4080),
            ),
            _StatCard(
              title: 'Categories',
              value: '${homeCtrl.totalCategories.value}',
              icon: Icons.category_outlined,
              iconBg: const Color(0xFF2A1E12),
              iconColor: const Color(0xFF7A3B1E),
            ),
          ],
        ));
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
