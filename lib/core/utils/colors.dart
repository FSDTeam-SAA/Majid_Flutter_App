import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme_controller.dart';

class AppColors {
  AppColors._();

  static ProfileThemePalette get _palette {
    if (Get.isRegistered<ProfileThemeController>()) {
      return Get.find<ProfileThemeController>().palette;
    }

    return ProfileThemeController.fallbackPalette;
  }

  static Color get background => _palette.backgroundColor;
  static Color get primary => _palette.primaryColor;
  static Color get textPrimary => _palette.textPrimary;
  static Color get textSecondary => _palette.textSecondary;
  static Color get fieldBackground => _palette.fieldBackgroundColor;
  static Color get fieldBorder => _palette.surfaceBorderColor;
  static Color get cardBackground => _palette.cardBackgroundColor;
  static Color get surfaceForeground => _palette.onPrimaryColor;
  static bool get isDark => _palette.brightness == Brightness.dark;
  static Color get overlayShadow => Colors.black.withValues(alpha: 0.18);
  static Color get modalBarrier => Colors.black.withValues(alpha: 0.45);
  static Color get successBackground =>
      _palette.primaryColor.withValues(alpha: isDark ? 0.18 : 0.12);
  static Color get errorBackground =>
      _palette.dangerColor.withValues(alpha: isDark ? 0.22 : 0.14);

  static String authBg = 'assets/images/bgimg.png';

  static Gradient get pageGradient => _palette.gradient;
}
