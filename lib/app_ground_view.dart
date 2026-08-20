import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/animation/app_motion.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/utils/colors.dart';
import 'core/widgets/app_bottom_nav_bar.dart';
import 'features/orders/presentation/pages/orders_page.dart';
import 'features/repair/presentation/pages/repair_page.dart';
import 'features/scan/presentation/pages/scan_device_page.dart';
import 'features/stock/presentation/pages/stock_page.dart';
import 'features/transactions/presentation/pages/transactions_home_page.dart';

class AppGroundView extends StatefulWidget {
  final int initialIndex;

  const AppGroundView({super.key, this.initialIndex = 0});

  @override
  State<AppGroundView> createState() => _AppGroundViewState();
}

class _AppGroundViewState extends State<AppGroundView> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 4);
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ProfileThemeController>();
    final pages = [
      OrdersPage(),
      StockPage(),
      ScanDevicePage(),
      const TransactionsHomePage(),
      RepairPage(),
    ];

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
          extendBody: true,
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: AppMotion.standard,
                  reverseDuration: AppMotion.quick,
                  switchInCurve: AppMotion.easeOutCubic,
                  switchOutCurve: AppMotion.easeInOut,
                  transitionBuilder: (child, animation) {
                    final slideAnimation =
                        Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: AppMotion.easeOutCubic,
                          ),
                        );

                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: slideAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: pages[_selectedIndex],
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                bottom: isKeyboardOpen ? -120 : 0,
                child: IgnorePointer(
                  ignoring: isKeyboardOpen,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isKeyboardOpen ? 0 : 1,
                    child: AppBottomNavBar(
                      selectedIndex: _selectedIndex,
                      onTap: _selectTab,
                    ),
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
