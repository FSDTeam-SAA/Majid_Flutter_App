import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../controller/profile_controller.dart';

class BusinessHealthScorePage extends StatefulWidget {
  const BusinessHealthScorePage({super.key});

  @override
  State<BusinessHealthScorePage> createState() =>
      _BusinessHealthScorePageState();
}

class _BusinessHealthScorePageState extends State<BusinessHealthScorePage> {
  late final ProfileController _profileCtrl;
  String _filter = 'monthly';

  @override
  void initState() {
    super.initState();
    _profileCtrl = Get.find<ProfileController>();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    // Ensure profile (userId) is loaded before fetching dashboard
    if (_profileCtrl.hasNoProfile) {
      await _profileCtrl.fetchProfile();
    }
    await _profileCtrl.fetchDashboardStats(filter: _filter);
  }

  Future<void> _refresh() => _profileCtrl.fetchDashboardStats(filter: _filter);

  void _setFilter(String f) {
    if (_filter == f) return;
    setState(() => _filter = f);
    _profileCtrl.fetchDashboardStats(filter: f);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              const AppHeader(title: 'Business Health Score'),
              Expanded(
                child: Obx(() {
                  if (_profileCtrl.isDashboardLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  final stats = _profileCtrl.dashboardStats.value;
                  if (stats == null) return _buildErrorState();

                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.cardBackground,
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                      child: _buildContent(stats),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load dashboard',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _refresh,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              shape: const StadiumBorder(),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(DashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(),
        const SizedBox(height: 18),
        _ScoreHeroCard(
          score: stats.healthScoreOverall,
          message: stats.healthScoreMessage,
        ),
        const SizedBox(height: 14),
        _BreakdownCard(metrics: stats.metrics),
        const SizedBox(height: 14),
        // Not CrossAxisAlignment.stretch: inside a scroll view that asks the
        // tiles for infinite height and takes the whole page down with it.
        // Both tiles have the same structure, so they match anyway.
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.payments_outlined,
                label: 'Total sales',
                value:
                    '${_profileCtrl.currencySymbol}${_compactNumber(stats.totalSales)}',
                caption: _periodLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.receipt_long_outlined,
                label: 'Orders',
                value: '${stats.totalOrders}',
                caption: _periodLabel,
              ),
            ),
          ],
        ),
        if (stats.insights.isNotEmpty) ...[
          const SizedBox(height: 14),
          _InsightsCard(insights: stats.insights),
        ],
      ],
    );
  }

  String get _periodLabel => switch (_filter) {
    'daily' => 'Today',
    'yearly' => 'This year',
    _ => 'This month',
  };

  /// `1467` -> `1,467`, `24500` -> `24.5k`, so a long figure never pushes the
  /// tile into an ellipsis.
  static String _compactNumber(double value) {
    if (value >= 100000) return '${(value / 1000).toStringAsFixed(0)}k';
    if (value >= 10000) return '${(value / 1000).toStringAsFixed(1)}k';
    final whole = value.toStringAsFixed(0);
    return whole.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
  }

  /// One segmented control rather than three loose pills, so the period reads
  /// as a single choice.
  Widget _buildFilterBar() {
    const options = {
      'daily': 'Daily',
      'monthly': 'Monthly',
      'yearly': 'Yearly',
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          for (final entry in options.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setFilter(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: _filter == entry.key
                        ? AppColors.cardBackground
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _filter == entry.key
                          ? AppColors.fieldBorder
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _filter == entry.key
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: _filter == entry.key
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Card styling shared by every block on this page, so they read as one set.
BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.cardBackground,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: AppColors.fieldBorder),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: AppColors.isDark ? 0.28 : 0.04),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ],
);

Widget _sectionTitle(String title, String subtitle) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
      ),
    ],
  );
}

/// The headline: one number, the band it falls in, and what to do about it.
class _ScoreHeroCard extends StatelessWidget {
  final int score;
  final String message;

  const _ScoreHeroCard({required this.score, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: _cardDecoration().copyWith(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = min(constraints.maxWidth, 300.0);
              return SizedBox(
                width: width,
                height: width * 0.62,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) => Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GaugePainter(
                            // Brand green, so the page matches the rest of
                            // the app. The band is carried by the badge and
                            // the number below, never by this arc alone.
                            color: AppColors.primary,
                            value: progress,
                            trackColor: AppColors.isDark
                                ? Colors.white.withValues(alpha: 0.10)
                                : Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(progress * 100).round()}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 52,
                                    fontWeight: FontWeight.w800,
                                    height: 1,
                                    letterSpacing: -2,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '/100',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'HEALTH SCORE',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // End labels, so the arc reads as a 0-100 scale rather
                      // than an abstract swoosh.
                      Positioned(left: 0, bottom: 0, child: _endLabel('0')),
                      Positioned(right: 0, bottom: 0, child: _endLabel('100')),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _endLabel(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _BreakdownCard extends StatelessWidget {
  final DashboardMetrics metrics;

  const _BreakdownCard({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Sales Growth', metrics.salesGrowth.score),
      ('Profit Margin', metrics.profitMargin.score),
      ('Checkout Management', metrics.stockManagement.score),
      ('Customer Satisfaction', metrics.customerSatisfaction.score),
      ('Outstanding Payments', metrics.outstandingPayments.score),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Score Breakdown', 'What each area contributes'),
          const SizedBox(height: 18),
          for (var i = 0; i < items.length; i++)
            _ScoreRow(
              label: items[i].$1,
              score: items[i].$2,
              // Stagger the bars slightly so the card resolves as one motion.
              delay: Duration(milliseconds: 60 * i),
            ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;
  final Duration delay;

  const _ScoreRow({
    required this.label,
    required this.score,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$score',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: score / 100),
                    duration: Duration(
                      milliseconds: 700 + delay.inMilliseconds,
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, progress, _) => Container(
                      height: 8,
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        // One hue for every row: the bar's length already says
                        // how big the score is, so the colour stays on brand
                        // instead of turning the card into a rainbow.
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.6),
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A plain figure. The old version drew a rising "trend" line that was the
/// same straight diagonal whatever the numbers were, i.e. a picture of data
/// that did not exist, so it is gone.
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final List<String> insights;

  const _InsightsCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: _sectionTitle(
                  'AI Insights',
                  'Generated from this period\'s numbers',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final insight in insights)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Half-circle gauge: a recessive full-range track with the score drawn over
/// it. The track used to be white at 10% opacity, which was invisible on the
/// light theme and left the arc floating with no scale behind it.
class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  const _GaugePainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 18.0;
    final center = Offset(size.width / 2, size.height - 14);
    final radius = min(size.width / 2, size.height) - strokeWidth;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // The track is split at the band boundaries (40 / 60 / 80) with a hairline
    // gap between segments, so the dial shows which zone the score sits in
    // instead of being one anonymous grey sweep.
    const bounds = [0.0, 0.4, 0.6, 0.8, 1.0];
    const gap = 0.012 * pi;
    for (var i = 0; i < bounds.length - 1; i++) {
      final start = pi + bounds[i] * pi + (i == 0 ? 0 : gap / 2);
      final end =
          pi + bounds[i + 1] * pi - (i == bounds.length - 2 ? 0 : gap / 2);
      canvas.drawArc(
        rect,
        start,
        end - start,
        false,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = i == 0 || i == bounds.length - 2
              ? StrokeCap.round
              : StrokeCap.butt,
      );
    }

    if (value <= 0) return;

    final sweep = pi * value.clamp(0.0, 1.0);
    final shader = SweepGradient(
      startAngle: pi,
      endAngle: 2 * pi,
      colors: [color.withValues(alpha: 0.72), color],
    ).createShader(rect);

    canvas.drawArc(
      rect,
      pi,
      sweep,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // A pip at the tip marks exactly where the score lands on the arc.
    final tipAngle = pi + sweep;
    final tip = Offset(
      center.dx + radius * cos(tipAngle),
      center.dy + radius * sin(tipAngle),
    );
    canvas.drawCircle(tip, 5, Paint()..color = Colors.white);
    canvas.drawCircle(
      tip,
      5,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.color != color || old.trackColor != trackColor;
}
