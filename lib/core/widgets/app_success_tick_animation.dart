import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated success icon: radiating bars sweep clockwise into a full ring on
/// a white card, then a blue circle with a white tick pops in with a haptic
/// bump.
///
/// Use for confirmation moments only (payment successful, invoice created,
/// IMEI check completed, stock added, repair completed, save successful) —
/// never for errors or as a loading indicator.
class AppSuccessTickAnimation extends StatefulWidget {
  final double size;
  final bool autoStart;
  final VoidCallback? onCompleted;
  final Color barColor;
  final Color centerColor;
  final Color tickColor;

  const AppSuccessTickAnimation({
    super.key,
    this.size = 180,
    this.autoStart = true,
    this.onCompleted,
    this.barColor = const Color(0xFF52B923),
    this.centerColor = const Color(0xFF1473EA),
    this.tickColor = Colors.white,
  });

  @override
  State<AppSuccessTickAnimation> createState() =>
      _AppSuccessTickAnimationState();
}

class _AppSuccessTickAnimationState extends State<AppSuccessTickAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hapticTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => play());
    }
  }

  Future<void> play() async {
    _hapticTriggered = false;
    await _controller.forward(from: 0);
    widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;

        final progress = value <= 0.70
            ? Curves.easeInOutCubic.transform(value / 0.70)
            : 1.0;

        var tickScale = 0.0;
        if (value >= 0.70) {
          final tickProgress = ((value - 0.70) / 0.30).clamp(0.0, 1.0);
          tickScale = Curves.elasticOut.transform(tickProgress);

          if (!_hapticTriggered && tickProgress > 0.05) {
            _hapticTriggered = true;
            HapticFeedback.mediumImpact();
          }
        }

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _SuccessPainter(
              progress: progress,
              tickScale: tickScale,
              barColor: widget.barColor,
              centerColor: widget.centerColor,
              tickColor: widget.tickColor,
            ),
          ),
        );
      },
    );
  }
}

class _SuccessPainter extends CustomPainter {
  const _SuccessPainter({
    required this.progress,
    required this.tickScale,
    required this.barColor,
    required this.centerColor,
    required this.tickColor,
  });

  final double progress;
  final double tickScale;
  final Color barColor;
  final Color centerColor;
  final Color tickColor;

  static const int barCount = 40;
  static const Color _inactiveBarColor = Color(0xFFE4E9E6);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.38;

    final cardRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.width * 0.32),
    );

    canvas.drawRRect(
      cardRect.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(cardRect, Paint()..color = Colors.white);

    const startAngle = -math.pi / 2;
    for (var i = 0; i < barCount; i++) {
      final angle = startAngle + (2 * math.pi * i / barCount);
      final isActive = i < progress * barCount;

      final paint = Paint()
        ..strokeWidth = size.width * 0.015
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..color = isActive ? barColor : _inactiveBarColor;

      final start = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final endRadius = radius + size.width * 0.075;
      final end = Offset(
        center.dx + math.cos(angle) * endRadius,
        center.dy + math.sin(angle) * endRadius,
      );

      canvas.drawLine(start, end, paint);
    }

    canvas.drawCircle(center, size.width * 0.23, Paint()..color = centerColor);

    if (tickScale > 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(tickScale);

      final tickPaint = Paint()
        ..color = tickColor
        ..strokeWidth = size.width * 0.055
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(-size.width * 0.095, 0)
        ..lineTo(-size.width * 0.025, size.width * 0.065)
        ..lineTo(size.width * 0.115, -size.width * 0.075);

      canvas.drawPath(path, tickPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.tickScale != tickScale ||
        oldDelegate.barColor != barColor ||
        oldDelegate.centerColor != centerColor ||
        oldDelegate.tickColor != tickColor;
  }
}
