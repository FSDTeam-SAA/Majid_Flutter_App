import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/colors.dart';

/// Bottom navigation pinned to the safe area.
///
/// The floating pill was dropped on the client's instruction ("move menu bar
/// below, no need to show floating menu bar anymore"). Docking it means page
/// content no longer scrolls underneath a translucent bar, so the checkout
/// keypad's Total Qty button stays fully visible above the navigation.
class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  /// Each destination carries either an asset icon or a Material one.
  ///
  /// Stock leads, per the client's "added Stock icon to the bottom menu": the
  /// tab that used to sit here listed sample ready-orders, and the live version
  /// of that list already sits on the Checkout screen.
  static const _destinations = <({String label, String? asset, IconData? icon})>[
    (label: 'Stock', asset: 'assets/navbar/stock.png', icon: null),
    (label: 'Checkout', asset: null, icon: Icons.calculate_rounded),
    (label: 'Scan', asset: 'assets/navbar/scan-qr.png', icon: null),
    (label: 'Transaction', asset: null, icon: Icons.swap_horiz_rounded),
    (label: 'Repairing', asset: 'assets/navbar/repair.png', icon: null),
  ];

  /// Height of the bar itself, before the device's bottom safe-area inset.
  static const barHeight = 64.0;

  /// Room a scrollable page should leave at the end of its content so the last
  /// row clears the docked bar.
  static double reservedHeight(BuildContext context) =>
      barHeight + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        border: Border(
          top: BorderSide(color: AppColors.fieldBorder.withValues(alpha: 0.7)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navShadow.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: barHeight,
          child: Row(
            children: List.generate(_destinations.length, (index) {
              final isSelected = index == selectedIndex;
              final destination = _destinations[index];
              final tint = isSelected
                  ? AppColors.primary
                  : AppColors.navInactive;

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
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            // 10% tint, no glow — the "subtle press state" the
                            // developer notes asked for.
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: destination.asset == null
                              ? Icon(destination.icon, size: 22, color: tint)
                              : Image.asset(
                                  destination.asset!,
                                  width: 21,
                                  height: 21,
                                  color: tint,
                                ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: tint,
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w600
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
    );
  }
}
