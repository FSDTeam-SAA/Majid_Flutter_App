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
  backgroundColor: Color(0xFF081B22),
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
  subtitle: 'Figma light surface',
  brightness: Brightness.light,
  backgroundColor: Color(0xFFD7EEFF),
  gradient: _lightProfileGradient,
  surfaceColor: Color(0xCCFFFFFF),
  surfaceBorderColor: Color(0xFFE4E7EC),
  primaryColor: Color(0xFF30D158),
  onPrimaryColor: Colors.white,
  textPrimary: Color(0xFF1A1C1E),
  textSecondary: Color(0xFF667085),
  fieldBackgroundColor: Color(0xFFF9FBFF),
  cardBackgroundColor: Color(0xFFFFFFFF),
  dangerColor: Color(0xFFD64545),
);

const _darkProfileGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xE6072A33),
    Color(0x9911434E),
    Color(0x9911434E),
    Color(0xE6072A33),
  ],
  stops: [0.0, 0.34, 0.66, 1.0],
);

const _lightProfileGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xF0BEE7FF),
    Color(0x88F4FBFF),
    Color(0x88F4FBFF),
    Color(0xF0BEE7FF),
  ],
  stops: [0.0, 0.34, 0.66, 1.0],
);
