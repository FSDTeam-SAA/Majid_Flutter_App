import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../controller/home_controller.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key});

  static const _lightIconBackgrounds = [
    Color(0xFFE6F4EA),
    Color(0xFFF1EBFF),
    Color(0xFFE8F1FF),
    Color(0xFFFFEFE2),
  ];

  static const _darkIconBackgrounds = [
    Color(0xFF1A3020),
    Color(0xFF1F1A35),
    Color(0xFF182232),
    Color(0xFF2A1E12),
  ];

  static const _iconColors = [
    Color(0xFF2D8A57),
    Color(0xFF6D55C8),
    Color(0xFF2E76C4),
    Color(0xFFC77638),
  ];

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();

    return Obx(
      () => GridView.count(
        key: ValueKey(AppColors.isDark),
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
            iconBg: AppColors.isDark
                ? _darkIconBackgrounds[0]
                : _lightIconBackgrounds[0],
            iconColor: _iconColors[0],
          ),
          _StatCard(
            title: 'Sold Products',
            value: '${homeCtrl.totalSoldProducts.value}',
            icon: Icons.shopping_cart_outlined,
            iconBg: AppColors.isDark
                ? _darkIconBackgrounds[1]
                : _lightIconBackgrounds[1],
            iconColor: _iconColors[1],
          ),
          _StatCard(
            title: 'Repair Requests',
            value: '${homeCtrl.totalRepairRequests.value}',
            icon: Icons.build_outlined,
            iconBg: AppColors.isDark
                ? _darkIconBackgrounds[2]
                : _lightIconBackgrounds[2],
            iconColor: _iconColors[2],
          ),
          _StatCard(
            title: 'Categories',
            value: '${homeCtrl.totalCategories.value}',
            icon: Icons.category_outlined,
            iconBg: AppColors.isDark
                ? _darkIconBackgrounds[3]
                : _lightIconBackgrounds[3],
            iconColor: _iconColors[3],
          ),
        ],
      ),
    );
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
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
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
