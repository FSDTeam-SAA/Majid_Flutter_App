import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/colors.dart';

/// Theme-aware design tokens for the checkout experience.
///
/// Every value resolves through [AppColors], so the keypad, product cards and
/// basket bar follow whichever palette (midnight / sunrise) is active instead
/// of the hardcoded light surfaces this screen used before.
class CheckoutTokens {
  CheckoutTokens._();

  static bool get isDark => AppColors.isDark;

  // Surfaces
  static Color get surface => isDark ? const Color(0xFF0E1F27) : Colors.white;
  static Color get surfaceRaised =>
      isDark ? const Color(0xFF14262F) : Colors.white;
  static Color get surfaceMuted =>
      isDark ? const Color(0xFF0B1A21) : const Color(0xFFF2F6FB);
  static Color get border =>
      isDark ? const Color(0xFF1D3742) : const Color(0xFFE4EAF2);
  static Color get borderStrong =>
      isDark ? const Color(0xFF27454F) : const Color(0xFFD5DFEB);

  // Text
  static Color get strongText => AppColors.textPrimary;
  static Color get softText => AppColors.textSecondary;
  static Color get ghostText => softText.withValues(alpha: 0.45);

  // Accent
  static Color get accent => AppColors.primary;
  static Color get onAccent => AppColors.surfaceForeground;
  static Color get accentSoft => accent.withValues(alpha: isDark ? 0.16 : 0.12);
  static Gradient get accentGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.lerp(accent, Colors.white, isDark ? 0.16 : 0.20)!, accent],
  );

  /// Recessed tray the keypad keys sit on.
  // The greys lean towards the palette they sit on - cool blue in sunrise,
  // teal navy in midnight - so the calculator reads as part of the app rather
  // than a neutral widget pasted on top.
  static Color get keypadPanel =>
      isDark ? const Color(0xFF0A1B22) : const Color(0xFFE7EEF6);

  /// Hairline that keeps the frosted keypad tray readable on the gradient.
  static Color get trayBorder => isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.white.withValues(alpha: 0.65);

  /// Fill of a single keypad key.
  static Color get keyFill =>
      isDark ? const Color(0xFF162C35) : const Color(0xFFF6FAFE);

  /// Numerals on the keypad: grey and light, as in the reference calculator.
  static Color get keyLabel =>
      isDark ? const Color(0xFFC3D3DA) : const Color(0xFF55636F);

  /// The big readout above the keys.
  static Color get readout => isDark ? Colors.white : const Color(0xFF3A3D40);

  /// Surface the readout sits on - plain white, no card.
  static Color get readoutSurface =>
      isDark ? const Color(0xFF0E2129) : Colors.white;

  static Color get readoutDivider =>
      isDark ? const Color(0xFF1B333D) : const Color(0xFFE6ECF3);

  /// Warm rail behind the arithmetic operators, matching the client mockup.
  static Color get operatorColor =>
      isDark ? const Color(0xFFF2564B) : const Color(0xFFF1463E);
  static Gradient get operatorGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: isDark
        // Softened a touch so it does not glare against the dark surfaces.
        ? const [Color(0xFFE8493F), Color(0xFFE8493F)]
        : const [Color(0xFFF0463E), Color(0xFFF0463E)],
  );

  static Color get danger => AppColors.dangerColor;
  static Color get dangerSoft => danger.withValues(alpha: isDark ? 0.18 : 0.10);

  /// Primary call to action (basket bar, sheet buttons).
  static Color get ctaBackground =>
      isDark ? Colors.white : const Color(0xFF101820);
  static Color get ctaForeground =>
      isDark ? const Color(0xFF06171E) : Colors.white;

  // Elevation
  static List<BoxShadow> shadow({double blur = 16, double y = 8}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.06),
      blurRadius: blur,
      offset: Offset(0, y),
    ),
  ];

  /// Barely-there lift for keypad keys.
  static List<BoxShadow> get keyShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.035),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> glow(
    Color color, {
    double blur = 22,
    double y = 10,
    double opacity = 1,
  }) => [
    BoxShadow(
      color: color.withValues(alpha: (isDark ? 0.26 : 0.28) * opacity),
      blurRadius: blur,
      offset: Offset(0, y),
    ),
  ];

  // Typography
  static TextStyle text({
    required double size,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.plusJakartaSans(
    color: color ?? strongText,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    height: height,
  );

  static TextStyle get label => text(
    size: 11.5,
    weight: FontWeight.w700,
    color: softText,
    letterSpacing: 0.6,
  );
}
