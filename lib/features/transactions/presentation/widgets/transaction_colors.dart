import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

/// Fixed accent palette for the Transactions/Reports/Cash Management screens
/// — uses bright, vibrant website greens matching the website lime/emerald palette.
abstract final class TransactionColors {
  /// Bright, vibrant website primary green (matching website #84CC16)
  static const green = Color(0xFF84CC16);

  /// Vivid bright green for badges, indicators, and positive amounts
  static const greenBright = Color(0xFF22C55E);

  /// Dynamic high-visibility green for text and labels
  static Color get greenDark =>
      AppColors.isDark ? const Color(0xFF84CC16) : const Color(0xFF65A30D);

  /// High-contrast text green
  static Color get greenText =>
      AppColors.isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

  static const coral = Color(0xFFFF6B4A);
  static const blue = Color(0xFF3B82F6);
}

