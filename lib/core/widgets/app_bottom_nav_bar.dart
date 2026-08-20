import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    'assets/navbar/dashboard.png',
    'assets/navbar/stock.png',
    'assets/navbar/scan-qr.png',
    'assets/navbar/invoice.png',
    'assets/navbar/repair.png',
  ];

  static const _labels = [
    'Orders',
    'Checkout',
    'Scan',
    'Transaction',
    'Repairing',
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const barHeight = 66.0;
    final floatMargin = 14.0 + bottomInset;

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, floatMargin),
      child: Container(
        height: barHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.navShadow,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.navBackground.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.navBackground.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Row(
                children: List.generate(_icons.length, (index) {
                  final isSelected = index == selectedIndex;

                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onTap(index),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                _icons[index],
                                width: 22,
                                height: 22,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.navInactive,
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: isSelected
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        _labels[index],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
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
        ),
      ),
    );
  }
}
