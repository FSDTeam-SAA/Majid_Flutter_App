import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/animation/app_entrance.dart';
import '../../../../core/theme/app_theme_controller.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/more_menu_button.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../stock/presentation/pages/add_new_device_page.dart';
import 'notifications_page.dart';
import '../controller/home_controller.dart';
import '../controller/home_data.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/cash_insight_card.dart';
import '../widgets/cash_management_card.dart';
import '../widgets/home_health_section.dart';
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
      _periodToFilter(homePeriodFromIndex(index)),
    );
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
            return const Center(
              child: AppLoadingIndicator(label: 'Loading dashboard...'),
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
                      _buildHeader().entrance(
                        index: 0,
                        begin: const Offset(0, 0.04),
                      ),
                      const SizedBox(height: 20),
                      _buildPeriodTabs().entrance(
                        index: 1,
                        begin: const Offset(0, 0.04),
                      ),
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
                            totalSales:
                                (d?['totalSales'] as num?)?.toDouble() ?? 0,
                            totalProfit:
                                (d?['totalProfit'] as num?)?.toDouble() ?? 0,
                            totalOrders:
                                (d?['totalOrders'] as num?)?.toInt() ?? 0,
                            avgOrderValue:
                                (d?['avgOrderValue'] as num?)?.toDouble() ?? 0,
                          ).entrance(index: 2);
                        }),
                        const SizedBox(height: 20),
                        QuickActions(
                          onAddRepair: () => widget.onOpenTab?.call(3),
                          onCreateInvoice: () => widget.onOpenTab?.call(4),
                          onAddItem: () =>
                              Get.to(() => const AddNewDevicePage()),
                        ).entrance(index: 3),
                        const SizedBox(height: 20),
                        SalesTrendChart(
                          periodLabel: salesTrend.periodLabel,
                          currentLegend: salesTrend.currentLegend,
                          previousLegend: salesTrend.previousLegend,
                          currentPeriod: salesTrend.currentValues,
                          previousPeriod: salesTrend.previousValues,
                          xLabels: salesTrend.axisLabels,
                          onPeriodTap: _showPeriodPicker,
                        ).entrance(index: 4),
                        const SizedBox(height: 20),
                        const CashInsightCard().entrance(index: 5),
                        const SizedBox(height: 20),
                        const HomeHealthSection().entrance(index: 6),
                        const SizedBox(height: 20),
                        const CashManagementCard().entrance(index: 7),
                        const SizedBox(height: 20),
                        const TopProductsList().entrance(index: 8),
                        const SizedBox(height: 20),
                        const AiInsightsCard().entrance(index: 9),
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
        Hero(
          tag: 'imoscan-brand-mark',
          child: Image.asset(
            'assets/images/imoscan_logo.png',
            width: 132,
            fit: BoxFit.contain,
          ),
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
        const MoreMenuButton(size: 38),
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
