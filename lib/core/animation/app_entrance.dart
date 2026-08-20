import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_motion.dart';

class AppEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset begin;
  final bool enableScale;

  const AppEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.duration = AppMotion.standard,
    this.begin = const Offset(0, 0.06),
    this.enableScale = true,
  });

  @override
  Widget build(BuildContext context) {
    final totalDelay = delay + (AppMotion.stagger * index);
    var animated = child
        .animate(delay: totalDelay)
        .fadeIn(duration: duration, curve: AppMotion.easeOutCubic)
        .slide(
          begin: begin,
          end: Offset.zero,
          duration: duration,
          curve: AppMotion.easeOutCubic,
        );

    if (enableScale) {
      animated = animated.scale(
        begin: const Offset(0.985, 0.985),
        end: const Offset(1, 1),
        duration: duration,
        curve: AppMotion.easeOutExpo,
      );
    }

    return animated;
  }
}

extension AppAnimateExtension on Widget {
  Widget entrance({
    int index = 0,
    Duration delay = Duration.zero,
    Duration duration = AppMotion.standard,
    Offset begin = const Offset(0, 0.06),
    bool enableScale = true,
  }) {
    return AppEntrance(
      index: index,
      delay: delay,
      duration: duration,
      begin: begin,
      enableScale: enableScale,
      child: this,
    );
  }
}
