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
  static Color get dangerColor => _palette.dangerColor;
  static bool get isDark => _palette.brightness == Brightness.dark;
  static Color get inputAccentBorder =>
      _palette.primaryColor.withValues(alpha: isDark ? 0.6 : 0.72);
  static Color get tabBackground =>
      isDark ? const Color(0xFF192638) : const Color(0xFFDEEBF5);
  static Color get tabBorder =>
      isDark ? const Color(0xFF223342) : const Color(0xFFC8DCF0);
  static Color get tabInactiveText =>
      isDark ? const Color(0xFFA9B3C1) : const Color(0xFF6B7E99);
  static Color get buttonText =>
      isDark ? _palette.onPrimaryColor : Colors.white;
  static Color get secondaryButtonText =>
      isDark ? _palette.textPrimary : Colors.white;
  static Color get secondaryButtonBackground => isDark
      ? Colors.transparent
      : _palette.primaryColor.withValues(alpha: 0.82);
  static Color get navBackground =>
      isDark ? const Color(0xFF0D171B) : Colors.white;
  static Color get navActiveBackground =>
      isDark ? Colors.white : const Color(0xFF101820);
  static Color get navActiveForeground =>
      isDark ? const Color(0xFF101820) : Colors.white;
  static Color get navActiveLabel => _palette.textPrimary;
  static Color get navInactive =>
      _palette.textSecondary.withValues(alpha: isDark ? 0.9 : 0.82);
  static Color get navShadow =>
      Colors.black.withValues(alpha: isDark ? 0.35 : 0.12);
  static Color get overlayShadow => Colors.black.withValues(alpha: 0.18);
  static Color get modalBarrier => Colors.black.withValues(alpha: 0.45);
  static Color get messageSurface =>
      isDark ? const Color(0xFF162128) : Colors.white.withValues(alpha: 0.97);
  static Color get successBorder =>
      _palette.primaryColor.withValues(alpha: isDark ? 0.34 : 0.26);
  static Color get errorBorder =>
      _palette.dangerColor.withValues(alpha: isDark ? 0.38 : 0.26);
  static Color get successText => _palette.textPrimary;
  static Color get errorText => _palette.textPrimary;
  static Color get successBackground =>
      isDark ? const Color(0xFF182722) : const Color(0xFFF3FFF6);
  static Color get errorBackground =>
      isDark ? const Color(0xFF2A1B1D) : const Color(0xFFFFF4F4);

  static String authBg = 'assets/images/bgimg.png';

  static Gradient get pageGradient => _palette.gradient;
}
