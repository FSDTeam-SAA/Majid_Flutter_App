import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../controller/home_controller.dart';
import 'score_card_header.dart';

class HomeHealthSection extends StatelessWidget {
  const HomeHealthSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();

    return Obx(() {
      final stats = ctrl.dashboardStats.value;
      if (stats == null) return const SizedBox.shrink();

      final health = stats['businessHealthScore'] as Map? ?? {};
      final overall = (health['overall'] as num?)?.toInt() ?? 0;
      final rating = health['rating']?.toString() ?? '';
      final message = health['message']?.toString() ?? '';

      final rawSalesGrowth = (stats['salesGrowth'] as num?)?.toDouble() ?? 0;
      final rawOrdersGrowth = (stats['ordersGrowth'] as num?)?.toDouble() ?? 0;
      final totalSales = (stats['totalSales'] as num?)?.toDouble() ?? 0;
      final totalOrders = (stats['totalOrders'] as num?)?.toInt() ?? 0;
      final inventoryValue = ctrl.totalInventoryValue;
      final repairs = ctrl.totalRepairRequests.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGaugeCard(overall, rating, message),
          const SizedBox(height: 12),
          _buildSummaryCard(rawSalesGrowth),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.shopping_cart_outlined,
                  iconBg: const Color(0xFF1A2A1A),
                  iconColor: const Color(0xFF4EE86A),
                  label: 'Sales',
                  value:
                      '${Get.find<ProfileController>().currencySymbol}${_fmt(totalSales)}',
                  growthPercent: rawSalesGrowth,
                  lineColor: const Color(0xFF4EE86A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.build_outlined,
                  iconBg: const Color(0xFF2A1800),
                  iconColor: const Color(0xFFE8920A),
                  label: 'Repairs',
                  value: '$repairs',
                  growthPercent: rawOrdersGrowth,
                  lineColor: const Color(0xFFE8920A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.inventory_2_outlined,
                  iconBg: const Color(0xFF182232),
                  iconColor: const Color(0xFF2E76C4),
                  label: 'Inventory',
                  value:
                      '${Get.find<ProfileController>().currencySymbol}${_fmt(inventoryValue)}',
                  growthPercent: null,
                  lineColor: const Color(0xFF2E76C4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.receipt_long_outlined,
                  iconBg: const Color(0xFF1F1A35),
                  iconColor: const Color(0xFF6D55C8),
                  label: 'Orders',
                  value: '$totalOrders',
                  growthPercent: rawOrdersGrowth,
                  lineColor: const Color(0xFF6D55C8),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }

  Widget _buildGaugeCard(int overall, String rating, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          const ScoreCardHeader(
            title: 'Business Health Score',
            infoMessage:
                'A blended score across sales growth, profit margin, stock management and customer satisfaction.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (ctx, c) {
              final w = c.maxWidth;
              final h = w * 0.46;
              return SizedBox(
                width: w,
                height: h,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GaugePainter(value: overall / 100.0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$overall%',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Health Score',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          if (rating.isNotEmpty)
            Text(
              message.isNotEmpty ? message : rating,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ratingColor(rating),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double salesGrowth) {
    final improved = salesGrowth >= 0;
    final pct = salesGrowth.abs().toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: improved
                  ? const Color(0xFF1A2A1A)
                  : const Color(0xFF2A1A1A),
              shape: BoxShape.circle,
            ),
            child: Icon(
              improved ? Icons.trending_up : Icons.trending_down,
              color: improved
                  ? const Color(0xFF4EE86A)
                  : const Color(0xFFE85050),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                improved
                    ? 'Sales up +$pct% vs last month'
                    : 'Sales down -$pct% vs last month',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'vs last month',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'Excellent':
        return const Color(0xFF4EE86A);
      case 'Good':
        return const Color(0xFF90EE90);
      case 'Fair':
        return const Color(0xFFE8B84E);
      case 'Needs Improvement':
        return const Color(0xFFE8920A);
      default:
        return const Color(0xFFE85050);
    }
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final double? growthPercent;
  final Color lineColor;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.growthPercent,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = growthPercent;
    final positive = pct == null || pct >= 0;
    final pctLabel = pct == null
        ? 'No comparison data'
        : pct >= 0
        ? '+${pct.abs().toStringAsFixed(1)}% vs last month'
        : '-${pct.abs().toStringAsFixed(1)}% vs last month';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            pctLabel,
            style: TextStyle(
              color: positive
                  ? const Color(0xFF4EE86A)
                  : const Color(0xFFE85050),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: CustomPaint(
              size: const Size(double.infinity, 38),
              painter: _TrendPainter(color: lineColor, positive: positive),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  const _GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final radius = size.width / 2 - 14;
    const strokeW = 18.0;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    canvas.drawArc(
      rect,
      pi,
      pi,
      false,
      Paint()
        ..shader = const SweepGradient(
          startAngle: pi,
          endAngle: 2 * pi,
          colors: [Color(0xFFE85050), Color(0xFFE8920A), Color(0xFF4EE86A)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    final needleAngle = pi + pi * value.clamp(0.0, 1.0);
    final needleLength = radius - strokeW / 2 - 4;
    final needleEnd = Offset(
      cx + needleLength * cos(needleAngle),
      cy + needleLength * sin(needleAngle),
    );
    canvas.drawLine(
      Offset(cx, cy),
      needleEnd,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}

class _TrendPainter extends CustomPainter {
  final Color color;
  final bool positive;
  const _TrendPainter({required this.color, required this.positive});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final start = Offset(0, h * 0.85);
    final end = Offset(w, h * 0.10);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.color != color || old.positive != positive;
}
