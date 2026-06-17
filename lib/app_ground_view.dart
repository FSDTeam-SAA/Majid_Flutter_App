import 'package:flutter/material.dart';

import 'core/utils/colors.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/invoice/presentation/pages/invoice_page.dart';
import 'features/repair/presentation/pages/repair_page.dart';
import 'features/scan/presentation/pages/scan_device_page.dart';
import 'features/stock/presentation/pages/stock_page.dart';

class AppGroundView extends StatefulWidget {
  const AppGroundView({super.key});

  @override
  State<AppGroundView> createState() => _AppGroundViewState();
}

class _AppGroundViewState extends State<AppGroundView> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    StockPage(),
    ScanDevicePage(),
    RepairPage(),
    InvoicePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _pages[_selectedIndex],
      bottomNavigationBar: _CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _CustomBottomNav extends StatelessWidget {
  const _CustomBottomNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.grid_view_rounded,
    Icons.inventory_2_outlined,
    Icons.qr_code_scanner_rounded,
    Icons.build_outlined,
    Icons.receipt_long_outlined,
  ];

  static const _labels = ['Dashboard', 'Stock', 'Scan', 'Repair', 'Invoice'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1A14),
        border: Border(top: BorderSide(color: Color(0xFF1E2E2A), width: 1)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) {
              final isCenter = i == 2;
              final isActive = selectedIndex == i;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isCenter) const SizedBox(height: 10),
                      if (!isCenter) ...[
                        Icon(
                          _icons[i],
                          color: isActive ? AppColors.primary : AppColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _labels[i],
                          style: TextStyle(
                            color: isActive ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
          Positioned(
            top: -22,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D1A14), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
