import 'package:flutter/material.dart';

import '../utils/colors.dart';

class GradientScaffold extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Gradient? gradient;

  const GradientScaffold({
    super.key,
    required this.child,
    this.backgroundColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedBackgroundColor = backgroundColor ?? AppColors.background;
    final resolvedGradient = gradient ?? AppColors.pageGradient;

    return Scaffold(
      backgroundColor: resolvedBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: resolvedBackgroundColor)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: resolvedGradient),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
