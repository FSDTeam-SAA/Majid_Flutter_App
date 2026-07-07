import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme_controller.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../profile/presentation/pages/profile_page_view.dart';
import '../../../stock/presentation/pages/add_new_device_page.dart';
import 'notifications_page.dart';
import '../controller/home_controller.dart';
import '../controller/home_data.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/sales_trend_chart.dart';
import '../widgets/stats_grid.dart';
import '../widgets/top_products_list.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<int>? onOpenTab;

  const HomePage({super.key, this.onOpenTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedPeriod = 0;
  late final HomeController homeCtrl;

  @override
  void initState() {
    super.initState();
    homeCtrl = Get.find<HomeController>();
  }

  String _periodToFilter(HomePeriod p) => switch (p) {
        HomePeriod.daily => 'daily',
        HomePeriod.weekly => 'monthly',
        HomePeriod.monthly => 'monthly',
        HomePeriod.yearly => 'yearly',
      };

  void _selectPeriod(int index) {
    setState(() => _selectedPeriod = index);
    homeCtrl.fetchDashboardForFilter(
        _periodToFilter(homePeriodFromIndex(index)));
  }

  Future<void> _showPeriodPicker() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
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
              children: List.generate(periods.length, (index) {
                final isSelected = index == _selectedPeriod;
                return ListTile(
                  onTap: () => Navigator.pop(context, index),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: isSelected
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : Colors.transparent,
                  title: Text(
                    periods[index],
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: AppColors.primary)
                      : null,
                );
              }),
            ),
          ),
        );
      },
    );

    if (selected != null) {
      _selectPeriod(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ProfileThemeController>();

    return Obx(() {
      themeCtrl.selectedTheme.value;
      return GradientScaffold(
        child: Obx(() {
          if (homeCtrl.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final selectedPeriod = homePeriodFromIndex(_selectedPeriod);
          final salesTrend = homeCtrl.salesTrendForPeriod(selectedPeriod);
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.cardBackground,
            onRefresh: homeCtrl.fetchAllData,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildPeriodTabs(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Obx(() {
                          final d = homeCtrl.dashboardStats.value;
                          return StatsGrid(
                            totalSales: (d?['totalSales'] as num?)?.toDouble() ?? 0,
                            totalProfit: (d?['totalProfit'] as num?)?.toDouble() ?? 0,
                            totalOrders: (d?['totalOrders'] as num?)?.toInt() ?? 0,
                            avgOrderValue: (d?['avgOrderValue'] as num?)?.toDouble() ?? 0,
                          );
                        }),
                        const SizedBox(height: 20),
                        QuickActions(
                          onAddRepair: () => widget.onOpenTab?.call(3),
                          onCreateInvoice: () => widget.onOpenTab?.call(4),
                          onAddItem: () => Get.to(() => const AddNewDevicePage()),
                        ),
                        const SizedBox(height: 20),
                        SalesTrendChart(
                          periodLabel: salesTrend.periodLabel,
                          currentLegend: salesTrend.currentLegend,
                          previousLegend: salesTrend.previousLegend,
                          currentPeriod: salesTrend.currentValues,
                          previousPeriod: salesTrend.previousValues,
                          xLabels: salesTrend.axisLabels,
                          onPeriodTap: _showPeriodPicker,
                        ),
                        const SizedBox(height: 20),
                        const TopProductsList(),
                        const SizedBox(height: 20),
                        const AiInsightsCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      );
    });
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/images/imoscan_logo.png',
          width: 132,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => Get.to(() => NotificationsPage()),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Get.to(() => ProfilePageView()),
          child: Obx(() {
            final imageUrl = homeCtrl.userImage.value;
            return CircleAvatar(
              radius: 19,
              backgroundColor: AppColors.cardBackground,
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Icon(Icons.person, color: AppColors.textPrimary),
                      )
                    : Icon(Icons.person, color: AppColors.textPrimary),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(periods.length, (i) {
          final selected = i == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectPeriod(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  periods[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? AppColors.background
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
