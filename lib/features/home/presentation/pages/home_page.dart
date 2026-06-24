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
  int _selectedPeriod = 2;
  late final HomeController homeCtrl;

  @override
  void initState() {
    super.initState();
    homeCtrl = Get.find<HomeController>();
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ProfileThemeController>();

    return Obx(
      () {
        themeCtrl.selectedTheme.value;
        return GradientScaffold(
          child: Obx(() {
            if (homeCtrl.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardBackground,
              onRefresh: homeCtrl.fetchAllData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildPeriodTabs(),
                    const SizedBox(height: 16),
                    const StatsGrid(),
                    const SizedBox(height: 20),
                    QuickActions(
                      onAddRepair: () => widget.onOpenTab?.call(3),
                      onCreateInvoice: () => widget.onOpenTab?.call(4),
                      onAddItem: () => Get.to(() => const AddNewDevicePage()),
                    ),
                    const SizedBox(height: 20),
                    SalesTrendChart(
                      thisMonth: thisMonthData,
                      lastMonth: lastMonthData,
                    ),
                    const SizedBox(height: 20),
                    const TopProductsList(),
                    const SizedBox(height: 20),
                    const AiInsightsCard(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'imo',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(
                text: 'scan',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 18),
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
              onTap: () => setState(() => _selectedPeriod = i),
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
