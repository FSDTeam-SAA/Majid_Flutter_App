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
    final navBackground = AppColors.navBackground;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const bubbleSize = 56.0;
    const barHeight = 72.0;
    const bubbleTop = -28.0;
    final totalHeight = barHeight + bottomInset;

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: totalHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _icons.length;
              final selectedCenter =
                  (tabWidth * selectedIndex) + (tabWidth / 2);
              final bubbleLeft = selectedCenter - (bubbleSize / 2);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: selectedCenter),
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      builder: (context, notchCenter, child) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, totalHeight),
                          painter: _NavBarBackgroundPainter(
                            color: navBackground,
                            shadowColor: AppColors.navShadow,
                            notchCenter: notchCenter,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomInset,
                    height: 64,
                    child: Row(
                      children: List.generate(_icons.length, (index) {
                        final isSelected = index == selectedIndex;
                        final iconColor = isSelected
                            ? Colors.transparent
                            : AppColors.navInactive;

                        return Expanded(
                          child: InkWell(
                            onTap: () => onTap(index),
                            borderRadius: BorderRadius.circular(0),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 11, 4, 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    _icons[index],
                                    color: iconColor,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    _labels[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.navActiveLabel
                                          : AppColors.navInactive,
                                      fontSize: 11,
                                      height: 1.1,
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
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: bubbleLeft,
                    top: bubbleTop,
                    child: Container(
                      width: bubbleSize,
                      height: bubbleSize,
                      decoration: BoxDecoration(
                        color: AppColors.navActiveBackground,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navShadow,
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Icon(
                        _icons[selectedIndex],
                        color: AppColors.navActiveForeground,
                        size: 24,
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

class _NavBarBackgroundPainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final double notchCenter;

  const _NavBarBackgroundPainter({
    required this.color,
    required this.shadowColor,
    required this.notchCenter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const top = 0.0;
    const radius = 22.0;
    const waveWidth = 112.0;
    const waveDepth = 40.0;

    final navBody = Path()
      ..moveTo(0, top)
      ..lineTo(size.width, top)
      ..lineTo(size.width, size.height - radius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - radius,
        size.height,
      )
      ..lineTo(radius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - radius)
      ..lineTo(0, top)
      ..close();

    final waveStart = (notchCenter - (waveWidth / 2))
        .clamp(0.0, size.width)
        .toDouble();
    final waveEnd = (notchCenter + (waveWidth / 2))
        .clamp(0.0, size.width)
        .toDouble();
    final carve = Path()
      ..moveTo(waveStart, top - 1)
      ..cubicTo(
        notchCenter - 32,
        top,
        notchCenter - 30,
        waveDepth,
        notchCenter,
        waveDepth,
      )
      ..cubicTo(
        notchCenter + 30,
        waveDepth,
        notchCenter + 32,
        top,
        waveEnd,
        top - 1,
      )
      ..lineTo(waveEnd, top - waveDepth)
      ..lineTo(waveStart, top - waveDepth)
      ..close();
    final path = Path.combine(PathOperation.difference, navBody, carve);

    canvas.drawShadow(path, shadowColor, 16, true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _NavBarBackgroundPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.notchCenter != notchCenter;
  }
}
