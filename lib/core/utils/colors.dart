import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0F14);
  static const Color primary = Color(0xFF8EFC7C);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF7A8A85);
  static const Color fieldBackground = Color(0xFF111A1E);
  static const Color fieldBorder = Color(0xFF1E2E2A);
  static const Color cardBackground = Color(0xFF131F1C);

  static const String authBg = 'assets/images/bgimg.png';

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1F2D), Color(0xFF060E0B)],
  );
}
