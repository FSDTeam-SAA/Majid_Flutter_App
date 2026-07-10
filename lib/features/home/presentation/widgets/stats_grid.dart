import 'package:flutter/material.dart';

import '../../../../core/animation/app_entrance.dart';
import '../../../../core/utils/colors.dart';

class StatsGrid extends StatelessWidget {
  final double totalSales;
  final double totalProfit;
  final int totalOrders;
  final double avgOrderValue;

  const StatsGrid({super.key, required this.totalSales, required this.totalProfit, required this.totalOrders, required this.avgOrderValue});

  static const _iconColors = [Color(0xFF2D8A57), Color(0xFF6D55C8), Color(0xFF2E76C4), Color(0xFFC77638)];
  static const _lightModeIcons = [
    'assets/lightmodeicon/TSL.png',
    'assets/lightmodeicon/tPL.png',
    'assets/lightmodeicon/toL.png',
    'assets/lightmodeicon/avgL.png',
  ];
  static const _darkModeIcons = [
    'assets/darkmodeicon/tsd.png',
    'assets/darkmodeicon/tpd.png',
    'assets/darkmodeicon/tod.png',
    'assets/darkmodeicon/aov.png',
  ];
  static const _iconAssetScale = 1.9;

  String _fmtCurrency(double v) {
    if (v >= 1000000) return '£${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '£${(v / 1000).toStringAsFixed(1)}k';
    return '£${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.bar_chart_rounded, 'Total Sales', _fmtCurrency(totalSales), _iconColors[0], _lightModeIcons[0], _darkModeIcons[0]),
      (
        Icons.account_balance_wallet_outlined,
        'Total Profit',
        _fmtCurrency(totalProfit),
        _iconColors[1],
        _lightModeIcons[1],
        _darkModeIcons[1],
      ),
      (Icons.shopping_bag_outlined, 'Total Orders', '$totalOrders', _iconColors[2], _lightModeIcons[2], _darkModeIcons[2]),
      (Icons.adjust_rounded, 'Avg Order Value', _fmtCurrency(avgOrderValue), _iconColors[3], _lightModeIcons[3], _darkModeIcons[3]),
    ];

    return GridView.builder(
      key: ValueKey(AppColors.isDark),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 152,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        return _StatCard(
          icon: entry.$1,
          title: entry.$2,
          value: entry.$3,
          iconColor: entry.$4,
          lightModeAsset: entry.$5,
          darkModeAsset: entry.$6,
        ).entrance(index: index, begin: const Offset(0, 0.045));
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final String lightModeAsset;
  final String darkModeAsset;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.lightModeAsset,
    required this.darkModeAsset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    final cardColor = isDark ? const Color(0xFF12161D).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5);
    final borderColor = isDark ? const Color(0xFF232A36) : const Color(0xFFE4E7EC);
    final titleColor = isDark ? const Color(0xFF8A96A8) : const Color(0xFF667085);
    final valueColor = isDark ? Colors.white : const Color(0xFF1A1C1E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (isDark)
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 58, offset: const Offset(0, 8))
          else
            BoxShadow(color: const Color(0xFFB8C7DE).withValues(alpha: 0.12), blurRadius: 50, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconBadge(isDark),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.w700, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBadge(bool isDark) {
    final asset = isDark ? darkModeAsset : lightModeAsset;
    final glowColor = iconColor.withValues(alpha: isDark ? 0.28 : 0.22);

    return SizedBox(
      width: 48,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: glowColor, blurRadius: 18, offset: const Offset(0, 0))],
        ),
        child: ClipRect(
          child: Transform.scale(
            scale: StatsGrid._iconAssetScale,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(icon, color: isDark ? Colors.white : iconColor, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
