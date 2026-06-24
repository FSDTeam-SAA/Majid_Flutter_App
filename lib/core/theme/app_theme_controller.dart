import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProfileThemeOption { midnight, sunrise }

class ProfileThemePalette {
  final String title;
  final String subtitle;
  final Brightness brightness;
  final Color backgroundColor;
  final Gradient gradient;
  final Color surfaceColor;
  final Color surfaceBorderColor;
  final Color primaryColor;
  final Color onPrimaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color fieldBackgroundColor;
  final Color cardBackgroundColor;
  final Color dangerColor;

  const ProfileThemePalette({
    required this.title,
    required this.subtitle,
    required this.brightness,
    required this.backgroundColor,
    required this.gradient,
    required this.surfaceColor,
    required this.surfaceBorderColor,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.fieldBackgroundColor,
    required this.cardBackgroundColor,
    required this.dangerColor,
  });
}

class ProfileThemeController extends GetxController {
  static const _storageKey = 'profile_theme_option';
  static const fallbackPalette = _midnightPalette;

  final selectedTheme = ProfileThemeOption.midnight.obs;

  ProfileThemePalette get palette => paletteFor(selectedTheme.value);

  ProfileThemePalette paletteFor(ProfileThemeOption option) => switch (option) {
    ProfileThemeOption.midnight => _midnightPalette,
    ProfileThemeOption.sunrise => _sunrisePalette,
  };

  bool isSelected(ProfileThemeOption option) => selectedTheme.value == option;

  @override
  void onInit() {
    super.onInit();
    _loadSavedTheme();
  }

  Future<void> setTheme(ProfileThemeOption option) async {
    if (selectedTheme.value == option) return;

    selectedTheme.value = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, option.name);
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOption = prefs.getString(_storageKey);

    if (savedOption == null) return;

    final match = ProfileThemeOption.values.where(
      (option) => option.name == savedOption,
    );
    if (match.isNotEmpty) {
      selectedTheme.value = match.first;
    }
  }
}

const _midnightPalette = ProfileThemePalette(
  title: 'Dark Mode',
  subtitle: 'Teal navy gradient',
  brightness: Brightness.dark,
  backgroundColor: Colors.black,
  gradient: _darkProfileGradient,
  surfaceColor: Color(0x8C101C24),
  surfaceBorderColor: Color(0xFF1E3640),
  primaryColor: Color(0xFF8EFC7C),
  onPrimaryColor: Colors.black,
  textPrimary: Colors.white,
  textSecondary: Color(0xFF89A2AC),
  fieldBackgroundColor: Color(0xFF111A1E),
  cardBackgroundColor: Color(0xFF131F1C),
  dangerColor: Color(0xFFE05A5A),
);

const _sunrisePalette = ProfileThemePalette(
  title: 'Light Mode',
  subtitle: 'Soft sky gradient',
  brightness: Brightness.light,
  backgroundColor: Colors.white,
  gradient: _lightProfileGradient,
  surfaceColor: Color(0xD9FFFFFF),
  surfaceBorderColor: Color(0xFFC9DDE8),
  primaryColor: Color(0xFF2B7A88),
  onPrimaryColor: Colors.white,
  textPrimary: Color(0xFF1B3640),
  textSecondary: Color(0xFF7695A0),
  fieldBackgroundColor: Color(0xFFF7FBFD),
  cardBackgroundColor: Color(0xFFFDFEFF),
  dangerColor: Color(0xFFBF4D4D),
);

const _darkProfileGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF073239),
    Color(0xFF0D243B),
    Color(0xFF090E15),
    Color(0xFF052A24),
  ],
  stops: [0.0, 0.34, 0.62, 1.0],
);

const _lightProfileGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment(0.72, 1.0),
  colors: [
    Color(0xFFC6EAEB),
    Color(0xFFC9DDF5),
    Color(0xFFF4F6FB),
    Color(0xFFFFFFFF),
  ],
  stops: [0.0, 0.34, 0.72, 1.0],
);
