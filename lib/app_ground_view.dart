import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'core/theme/app_theme_controller.dart';
import 'core/utils/colors.dart';
import 'core/widgets/app_bottom_nav_bar.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/invoice/presentation/pages/invoice_page.dart';
import 'features/repair/presentation/pages/repair_page.dart';
import 'features/scan/presentation/pages/scan_device_page.dart';
import 'features/stock/presentation/pages/stock_page.dart';

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
      HomePage(onOpenTab: _selectTab),
      StockPage(),
      ScanDevicePage(),
      RepairPage(),
      InvoicePage(),
    ];

    return Obx(() {
      themeCtrl.selectedTheme.value;
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
              Positioned.fill(child: pages[_selectedIndex]),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppBottomNavBar(
                  selectedIndex: _selectedIndex,
                  onTap: _selectTab,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
