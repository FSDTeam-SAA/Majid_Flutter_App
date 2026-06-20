import 'package:flutter/material.dart';

import 'core/utils/colors.dart';
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
    final pages = [
      HomePage(onOpenTab: _selectTab),
      const StockPage(),
      const ScanDevicePage(),
      const RepairPage(),
      const InvoicePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_selectedIndex],
      bottomNavigationBar: _CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _selectTab,
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
    Icons.inventory_2_rounded,
    Icons.qr_code_scanner_rounded,
    Icons.build_rounded,
    Icons.receipt_long_outlined,
  ];

  static const _labels = ['Dashboard', 'Stock', 'Scan', 'Repair', 'Invoice'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 132,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / _labels.length;
            final activeCenter = tabWidth * (selectedIndex + 0.5);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(color: Colors.black),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  top: 24,
                  left: activeCenter - 52,
                  child: IgnorePointer(
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        color: Color(0xFF062A20),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  top: 0,
                  left: activeCenter - 43,
                  child: IgnorePointer(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE9EEF6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _icons[selectedIndex],
                        color: const Color(0xFF101820),
                        size: 34,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: List.generate(_labels.length, (i) {
                      final isActive = selectedIndex == i;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onTap(i),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            children: [
                              SizedBox(height: isActive ? 91 : 56),
                              if (!isActive) ...[
                                Icon(
                                  _icons[i],
                                  color: const Color(0xFFA0A9B5),
                                  size: 30,
                                ),
                                const SizedBox(height: 8),
                              ],
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _labels[i],
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFFA0A9B5),
                                      fontSize: isActive ? 18 : 17,
                                      fontWeight: isActive
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
