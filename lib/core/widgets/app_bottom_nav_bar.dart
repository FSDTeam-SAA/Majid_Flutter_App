import 'package:flutter/material.dart';

import '../utils/colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

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
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: SizedBox(
          height: 88,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _icons.length;
              final bubbleLeft =
                  (tabWidth * selectedIndex) + (tabWidth / 2) - 24;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        //color: Color(0xFF3A3C33),
                        borderRadius: BorderRadius.circular(0),
                        //boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, -4))],
                      ),
                      child: Row(
                        children: List.generate(_icons.length, (index) {
                          final isSelected = index == selectedIndex;
                          final iconColor = isSelected
                              ? Colors.transparent
                              : AppColors.textPrimary.withValues(alpha: 0.88);

                          return Expanded(
                            child: InkWell(
                              onTap: () => onTap(index),
                              borderRadius: BorderRadius.circular(0),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      _icons[index],
                                      color: iconColor,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _labels[index],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppColors.textPrimary
                                            : AppColors.textPrimary.withValues(
                                                alpha: 0.72,
                                              ),
                                        fontSize: 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: bubbleLeft,
                    top: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.cardBackground,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.overlayShadow,
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Icon(
                          _icons[selectedIndex],
                          color: AppColors.surfaceForeground,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
