import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../animation/app_motion.dart';
import '../utils/colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  final String? label;
  final double size;
  final Color? color;

  const AppLoadingIndicator({
    super.key,
    this.label,
    this.size = 28,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.6,
        color: color ?? AppColors.primary,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(
      begin: const Offset(0.92, 0.92),
      end: const Offset(1.04, 1.04),
      duration: AppMotion.slow,
      curve: AppMotion.easeInOut,
    ).fadeIn(
      duration: AppMotion.quick,
      curve: AppMotion.easeOutCubic,
    );

    if (label == null) {
      return indicator;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: 14),
        Text(
          label!,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(
          delay: const Duration(milliseconds: 120),
          duration: AppMotion.standard,
          curve: AppMotion.easeOutCubic,
        ),
      ],
    );
  }
}
