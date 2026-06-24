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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profileCtrl = Get.find<ProfileController>();
    _loadData();
  }

  Future<void> _loadData() async {
    await _profileCtrl.fetchBusinessHealthData();
    if (mounted) setState(() => _isLoading = false);
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
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 40),
                        child: Obx(() => _buildContent()),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final repairs = _profileCtrl.totalRepairs.value;
    final inventory = _profileCtrl.totalInventoryItems.value;

    return Column(
      children: [
        _buildGaugeCard(),
        SizedBox(height: 12),
        _buildImprovementCard(),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.shopping_cart_outlined,
                iconBgColor: AppColors.fieldBackground,
                iconColor: AppColors.primary,
                label: 'Sales',
                value: 'N/A',
                change: 'API not available',
                changePositive: true,
                lineColor: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.build_outlined,
                iconBgColor: Color(0xFF2A1800),
                iconColor: Color(0xFFE8920A),
                label: 'Repairs',
                value: '$repairs',
                change: 'Total requests',
                changePositive: true,
                lineColor: Color(0xFFE8920A),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.inventory_2_outlined,
                iconBgColor: AppColors.fieldBackground,
                iconColor: AppColors.primary,
                label: 'Inventory',
                value: '$inventory',
                change: 'Total items',
                changePositive: true,
                lineColor: AppColors.primary,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.replay_outlined,
                iconBgColor: Color(0xFF2A0808),
                iconColor: Color(0xFFE85050),
                label: 'Returns',
                value: 'N/A',
                change: 'API not available',
                changePositive: false,
                lineColor: Color(0xFFE85050),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFF111B1F),
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
              decoration: BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.fieldBorder,
                        child: Icon(
                          Icons.person,
                          color: AppColors.textPrimary,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      color: AppColors.fieldBorder,
                      child: Icon(
                        Icons.person,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGaugeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
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
                      child: CustomPaint(painter: _GaugePainter(value: 0.0)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'N/A',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 2),
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
          SizedBox(height: 16),
          Text(
            'Dashboard API needed for full score',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder, width: 1),
      ),
      child: Row(
        children: [
          _CircleIcon(
            bgColor: AppColors.fieldBackground,
            icon: Icons.info_outline,
            iconColor: AppColors.primary,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health score requires dashboard API',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Sales & profit data not yet available',
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
  }
}

class _CircleIcon extends StatelessWidget {
  final Color bgColor;
  final IconData icon;
  final Color iconColor;

  const _CircleIcon({
    required this.bgColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22),
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
        colors: [Color(0xFF4EE86A), Color(0xFFACFF7A)],
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
      padding: EdgeInsets.all(14),
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
              SizedBox(width: 8),
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
          SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              color: changePositive ? AppColors.primary : Color(0xFFE85050),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: CustomPaint(
              size: Size(double.infinity, 44),
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
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)],
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
