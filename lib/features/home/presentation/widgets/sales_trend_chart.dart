import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class SalesTrendChart extends StatelessWidget {
  final List<double> thisMonth;
  final List<double> lastMonth;

  const SalesTrendChart({
    super.key,
    required this.thisMonth,
    required this.lastMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                'Sales Trend',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.fieldBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textPrimary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(AppColors.primary, 'This Month'),
              const SizedBox(width: 16),
              _legendDot(AppColors.textSecondary, 'Last Month'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: Size(double.infinity, 160),
              painter: _ChartPainter(
                thisMonth: thisMonth,
                lastMonth: lastMonth,
                isDark: AppColors.isDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              Text(
                '7',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              Text(
                '14',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
              Text(
                '18',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> thisMonth;
  final List<double> lastMonth;
  final bool isDark;

  const _ChartPainter({
    required this.thisMonth,
    required this.lastMonth,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = [...thisMonth, ...lastMonth];
    final maxVal = allValues.reduce(max);
    final minVal = allValues.reduce(min) * 0.8;

    final gridPaint = Paint()
      ..color = AppColors.fieldBorder.withValues(alpha: AppColors.isDark ? 0.28 : 0.42)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const yLabels = ['18000', '13500', '9000', '4500', '0'];
    final textStyle = TextStyle(
      color: AppColors.textSecondary.withValues(alpha: 0.75),
      fontSize: 9,
    );
    for (int i = 0; i < yLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, size.height * i / 4 - 6));
    }

    _drawLine(
      canvas,
      size,
      lastMonth,
      AppColors.textSecondary.withValues(alpha: 0.85),
      minVal,
      maxVal,
    );
    _drawLine(
      canvas,
      size,
      thisMonth,
      AppColors.primary,
      minVal,
      maxVal,
      drawDots: true,
    );
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double> data,
    Color color,
    double minVal,
    double maxVal, {
    bool drawDots = false,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final n = data.length;
    final path = Path();

    double x(int i) => size.width * i / (n - 1);
    double y(int i) =>
        size.height - (data[i] - minVal) / (maxVal - minVal) * size.height;

    path.moveTo(x(0), y(0));
    for (int i = 1; i < n; i++) {
      final cpX = (x(i - 1) + x(i)) / 2;
      path.cubicTo(cpX, y(i - 1), cpX, y(i), x(i), y(i));
    }
    canvas.drawPath(path, paint);

    if (drawDots) {
      for (int i = 0; i < n; i++) {
        canvas.drawCircle(Offset(x(i), y(i)), 4, Paint()..color = color);
        canvas.drawCircle(
          Offset(x(i), y(i)),
          4,
          Paint()
            ..color = AppColors.cardBackground
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.isDark != isDark;
}
