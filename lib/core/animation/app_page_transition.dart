import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_motion.dart';

class AppPageTransitions {
  const AppPageTransitions._();

  static PageTransitionsTheme get theme => PageTransitionsTheme(
    builders: {
      for (final platform in TargetPlatform.values)
        platform: const _FadeSlidePageTransitionsBuilder(),
    },
  );

  static CustomTransition get getx => _AppGetPageTransition();
}

class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == null && route.fullscreenDialog) {
      return child;
    }

    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOutCubic,
      reverseCurve: AppMotion.easeInOut,
    );
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.88, curve: AppMotion.easeOutExpo),
      reverseCurve: const Interval(0, 1, curve: AppMotion.easeInOut),
    );
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(curvedAnimation);
    final scaleAnimation = Tween<double>(begin: 0.985, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppMotion.easeOutExpo,
        reverseCurve: AppMotion.easeInOut,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      ),
    );
  }
}

class _AppGetPageTransition extends CustomTransition {
  _AppGetPageTransition();

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.88, curve: AppMotion.easeOutExpo),
      reverseCurve: const Interval(0, 1, curve: AppMotion.easeInOut),
    );
    final slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: animation,
            curve: AppMotion.easeOutCubic,
            reverseCurve: AppMotion.easeInOut,
          ),
        );
    final scaleAnimation = Tween<double>(begin: 0.985, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppMotion.easeOutExpo,
        reverseCurve: AppMotion.easeInOut,
      ),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      ),
    );
  }
}
