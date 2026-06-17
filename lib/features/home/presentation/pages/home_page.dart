import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

import '../../../../core/utils/colors.dart';
import '../../../profile/presentation/pages/profile_page_view.dart';
import '../controller/home_data.dart';
import '../widgets/ai_insights_card.dart';
import '../widgets/quick_actions.dart';
import '../widgets/sales_trend_chart.dart';
import '../widgets/stats_grid.dart';
import '../widgets/top_products_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedPeriod = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
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
              const QuickActions(),
              const SizedBox(height: 20),
              const SalesTrendChart(thisMonth: thisMonthData, lastMonth: lastMonthData),
              const SizedBox(height: 20),
              const TopProductsList(products: topProducts),
              const SizedBox(height: 20),
              const AiInsightsCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'imo', style: TextStyle(color: AppColors.primary)),
              TextSpan(text: 'scan', style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.verified, color: Color(0xFF1DA1F2), size: 18),
        const Spacer(),
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: AppColors.cardBackground, shape: BoxShape.circle, border: Border.all(color: AppColors.fieldBorder)),
          child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => Get.to(() => const ProfilePageView()),
          child: CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.cardBackground,
            child: ClipOval(
              child: Image.network('https://i.pravatar.cc/100', fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.person, color: AppColors.textPrimary)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: List.generate(periods.length, (i) {
          final selected = i == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: selected ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(9)),
                child: Text(
                  periods[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(color: selected ? AppColors.background : AppColors.textSecondary, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
