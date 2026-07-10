import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = "access_token";
  static const _refreshKey = "refresh_key";
  static const _role = "role";
  static const _installMarkerKey = "app_install_marker_v1";
  static const _onboardingSeenKey = "onboarding_seen_v1";

  static Future<void> saveToken({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  static Future<void> accessToken(String token) async {
    debugPrint("Saving token is $token");
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<void> saveRole(String token) async {
    await _storage.write(key: _role, value: token);
  }

  static Future<void> refreshToken(String token) async {
    await _storage.write(key: _refreshKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _role);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshKey);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _role);
  }

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> clearPersistedSessionOnFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final hasInstallMarker = prefs.getBool(_installMarkerKey) ?? false;

    if (!hasInstallMarker) {
      await clearToken();
      await prefs.setBool(_installMarkerKey, true);
    }
  }
}
