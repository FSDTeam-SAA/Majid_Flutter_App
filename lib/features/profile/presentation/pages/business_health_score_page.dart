import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
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
    if (_profileCtrl.profileData.isEmpty) {
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
              _buildHeader(context),
              Expanded(
                child: Obx(() {
                  if (_profileCtrl.isDashboardLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  final stats = _profileCtrl.dashboardStats.value;
                  if (stats == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_outlined,
                              color: AppColors.textSecondary, size: 48),
                          const SizedBox(height: 12),
                          Text('Could not load dashboard',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _refresh,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.cardBackground,
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
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

  Widget _buildContent(Map<String, dynamic> stats) {
    final health = stats['businessHealthScore'] as Map? ?? {};
    final metrics = stats['metrics'] as Map? ?? {};
    final insights = (stats['insights'] as List?)?.cast<String>() ?? [];

    final overall = (health['overall'] as num?)?.toInt() ?? 0;
    final rating = health['rating']?.toString() ?? '';
    final message = health['message']?.toString() ?? '';

    final totalSales = (stats['totalSales'] as num?)?.toDouble() ?? 0;
    final totalOrders = (stats['totalOrders'] as num?)?.toInt() ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterRow(),
        const SizedBox(height: 12),
        _buildGaugeCard(overall, rating, message),
        const SizedBox(height: 12),
        _buildScoreBreakdown(metrics),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.shopping_cart_outlined,
                iconBgColor: AppColors.fieldBackground,
                iconColor: AppColors.primary,
                label: 'Sales',
                value: '£${totalSales.toStringAsFixed(0)}',
                change: 'Total revenue',
                changePositive: true,
                lineColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.receipt_long_outlined,
                iconBgColor: const Color(0xFF1A2A1A),
                iconColor: const Color(0xFF4EE86A),
                label: 'Orders',
                value: '$totalOrders',
                change: 'Total orders',
                changePositive: true,
                lineColor: const Color(0xFF4EE86A),
              ),
            ),
          ],
        ),
        if (insights.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInsightsCard(insights),
        ],
      ],
    );
  }

  Widget _buildFilterRow() {
    return Row(
      children: [
        _FilterChip(label: 'Daily', selected: _filter == 'daily', onTap: () => _setFilter('daily')),
        const SizedBox(width: 8),
        _FilterChip(label: 'Monthly', selected: _filter == 'monthly', onTap: () => _setFilter('monthly')),
        const SizedBox(width: 8),
        _FilterChip(label: 'Yearly', selected: _filter == 'yearly', onTap: () => _setFilter('yearly')),
      ],
    );
  }

  Widget _buildGaugeCard(int overall, String rating, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder, width: 1),
      ),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final gaugeH = w * 0.54;
              return SizedBox(
                width: w,
                height: gaugeH,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                          painter: _GaugePainter(value: overall / 100.0)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$overall',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Health Score',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              letterSpacing: 0.2,
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
          const SizedBox(height: 16),
          if (rating.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: _ratingColor(rating).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _ratingColor(rating).withValues(alpha: 0.4)),
              ),
              child: Text(
                rating,
                style: TextStyle(
                  color: _ratingColor(rating),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(Map metrics) {
    final items = [
      ('Sales Growth', metrics['salesGrowth']),
      ('Profit Margin', metrics['profitMargin']),
      ('Checkout Management', metrics['stockManagement']),
      ('Customer Satisfaction', metrics['customerSatisfaction']),
      ('Outstanding Payments', metrics['outstandingPayments']),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map((entry) {
            final label = entry.$1;
            final metric = entry.$2 as Map?;
            final score = (metric?['score'] as num?)?.toInt() ?? 0;
            return _ScoreRow(label: label, score: score);
          }),
        ],
      ),
    );
  }

  Widget _buildInsightsCard(List<String> insights) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                insight,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF111B1F),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Business Health Score',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Obx(() {
            final url = _profileCtrl.imageUrl;
            return Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.fieldBorder,
                        child: Icon(Icons.person,
                            color: AppColors.textPrimary, size: 24),
                      ),
                    )
                  : Container(
                      color: AppColors.fieldBorder,
                      child: Icon(Icons.person,
                          color: AppColors.textPrimary, size: 24),
                    ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int score;

  const _ScoreRow({required this.label, required this.score});

  Color get _barColor {
    if (score >= 85) return const Color(0xFF4EE86A);
    if (score >= 70) return const Color(0xFF90EE90);
    if (score >= 55) return const Color(0xFFE8B84E);
    if (score >= 40) return const Color(0xFFE8920A);
    return const Color(0xFFE85050);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                '$score/100',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 6,
              backgroundColor: AppColors.fieldBorder,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String value;
  final String change;
  final bool changePositive;
  final Color lineColor;

  const _MetricCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.change,
    required this.changePositive,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 19),
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
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              color:
                  changePositive ? AppColors.primary : const Color(0xFFE85050),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: CustomPaint(
              size: const Size(double.infinity, 44),
              painter: _TrendLinePainter(
                color: lineColor,
                positive: changePositive,
              ),
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
    final center = Offset(cx, cy);
    final radius = size.width / 2 - 16;
    const strokeW = 22.0;
    const startAngle = pi;
    const sweepAll = pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAll,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    if (value > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final shader = SweepGradient(
        startAngle: pi,
        endAngle: 2 * pi,
        colors: const [Color(0xFF4EE86A), Color(0xFFACFF7A)],
      ).createShader(rect);

      canvas.drawArc(
        rect,
        startAngle,
        sweepAll * value,
        false,
        Paint()
          ..shader = shader
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}

class _TrendLinePainter extends CustomPainter {
  final Color color;
  final bool positive;
  const _TrendLinePainter({required this.color, required this.positive});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final start = Offset(0, h * 0.88);
    final end = Offset(w, h * 0.12);

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
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.0)
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter old) =>
      old.color != color || old.positive != positive;
}
