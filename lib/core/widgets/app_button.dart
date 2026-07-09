import 'package:flutter/material.dart';

import '../animation/pressable_scale.dart';
import 'app_loading_indicator.dart';
import '../utils/colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      enabled: !isLoading && onPressed != null,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surfaceForeground,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: isLoading
                ? AppLoadingIndicator(
                    key: const ValueKey('loading'),
                    size: 22,
                    color: AppColors.surfaceForeground,
                  )
                : Text(
                    label,
                    key: const ValueKey('label'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
