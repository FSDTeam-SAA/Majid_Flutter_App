import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme_controller.dart';
import 'core/utils/colors.dart';
import 'core/widgets/app_bottom_nav_bar.dart';
import 'features/repair/presentation/pages/repair_page.dart';
import 'features/scan/presentation/pages/scan_device_page.dart';
import 'features/stock/presentation/pages/stock_categories_page.dart';
import 'features/stock/presentation/pages/stock_page.dart';
import 'features/transactions/presentation/pages/transactions_home_page.dart';
import 'features/staff/presentation/controller/staff_session_controller.dart';
import 'features/staff/presentation/widgets/switch_staff_sheet.dart';

class AppGroundView extends StatefulWidget {
  final int initialIndex;

  const AppGroundView({super.key, this.initialIndex = 0});

  @override
  State<AppGroundView> createState() => _AppGroundViewState();
}

class _AppGroundViewState extends State<AppGroundView> {
  late int _selectedIndex;
  final Map<int, Widget> _visitedPages = {};

  Widget _page(int index) => _visitedPages.putIfAbsent(
    index,
    () => switch (index) {
      0 => const StockCategoriesPage(),
      1 => StockPage(),
      2 => ScanDevicePage(),
      3 => const TransactionsHomePage(),
      _ => RepairPage(),
    },
  );

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 4);
  }

  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ProfileThemeController>();
    final staffSession = StaffSessionController.instance;

    return Obx(() {
      themeCtrl.selectedTheme.value;
      final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: AppColors.isDark
              ? Brightness.light
              : Brightness.dark,
        ),
        child: Scaffold(
          // Docked (not floating) navigation, so pages end above the bar
          // instead of scrolling underneath it.
          extendBody: false,
          backgroundColor: AppColors.background,
          bottomNavigationBar: isKeyboardOpen
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedIndex == 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                staffSession.staffName.value.isEmpty
                                    ? 'Serving as Owner'
                                    : 'Serving as ${staffSession.staffName.value}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => showSwitchStaffSheet(context),
                              child: const Text('Switch Staff'),
                            ),
                          ],
                        ),
                      ),
                    AppBottomNavBar(
                      selectedIndex: _selectedIndex,
                      onTap: _selectTab,
                    ),
                  ],
                ),
          body: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: List.generate(
                    5,
                    (index) =>
                        _visitedPages.containsKey(index) ||
                            index == _selectedIndex
                        ? TickerMode(
                            enabled: index == _selectedIndex,
                            child: _page(index),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
