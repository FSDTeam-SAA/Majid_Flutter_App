import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../controller/home_controller.dart';
import 'score_card_header.dart';

class CashInsightCard extends StatefulWidget {
  const CashInsightCard({super.key});

  @override
  State<CashInsightCard> createState() => _CashInsightCardState();
}

class _CashInsightCardState extends State<CashInsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();

    return Obx(() {
      final cash = homeCtrl.cashManagement.value;
      if (cash == null) return const SizedBox.shrink();

      final score = (cash['cashManagementScore'] as num?)?.toInt() ?? 0;
      final insight = cash['aiInsight']?.toString() ?? '';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          children: [
            const ScoreCardHeader(
              title: 'Cash Management Score',
              infoMessage:
                  'Reflects how well your starting day cash, banked cash and cash in drawer reconcile. A low score means cash handling needs urgent review.',
            ),
            const SizedBox(height: 20),
            LayoutBuilder(builder: (ctx, c) {
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
                        painter: _CashGaugePainter(value: score / 100.0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2A1A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Color(0xFF4EE86A), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Current record',
                    style: TextStyle(
                      color: Color(0xFF4EE86A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (insight.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                insight,
                textAlign: TextAlign.center,
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'See less' : 'See more',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _CashGaugePainter extends CustomPainter {
  final double value;
  const _CashGaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final radius = size.width / 2 - 14;
    const strokeW = 18.0;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      pi, pi, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    if (value > 0) {
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      canvas.drawArc(
        rect, pi, pi * value, false,
        Paint()
          ..shader = SweepGradient(
            startAngle: pi,
            endAngle: 2 * pi,
            colors: const [Color(0xFFE85050), Color(0xFFE8920A)],
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CashGaugePainter old) => old.value != value;
}
