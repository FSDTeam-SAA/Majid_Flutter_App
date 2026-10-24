import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeviceBiometricType {
  none,
  face,
  fingerprint,
  multiple,
  generic,
}

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  static const _biometricEnabledPrefKey = 'biometric_login_enabled_v1';
  static const _savedEmailKey = 'biometric_saved_email_v1';
  static const _savedPasswordKey = 'biometric_saved_password_v1';

  /// Whether the device hardware supports biometrics and has enrolled biometrics
  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck || isDeviceSupported;
    } on PlatformException catch (e) {
      debugPrint('Biometric check error: $e');
      return false;
    }
  }

  /// Get specific enrolled biometric types on this device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Biometric list error: $e');
      return [];
    }
  }

  /// Categorize the primary biometric capability
  Future<DeviceBiometricType> getPrimaryBiometricType() async {
    final available = await getAvailableBiometrics();
    if (available.isEmpty) {
      final canCheck = await canCheckBiometrics();
      return canCheck ? DeviceBiometricType.generic : DeviceBiometricType.none;
    }

    final hasFace = available.contains(BiometricType.face);
    final hasFingerprint = available.contains(BiometricType.fingerprint) ||
        available.contains(BiometricType.strong);

    if (hasFace && hasFingerprint) {
      return DeviceBiometricType.multiple;
    } else if (hasFace) {
      return DeviceBiometricType.face;
    } else if (hasFingerprint) {
      return DeviceBiometricType.fingerprint;
    }

    return DeviceBiometricType.generic;
  }

  /// Human-readable label for UI buttons and settings tiles
  String getBiometricLabel(DeviceBiometricType type) {
    switch (type) {
      case DeviceBiometricType.face:
        return 'Face ID';
      case DeviceBiometricType.fingerprint:
        return 'Fingerprint';
      case DeviceBiometricType.multiple:
        return 'Face ID / Fingerprint';
      case DeviceBiometricType.generic:
        return 'Biometrics';
      case DeviceBiometricType.none:
        return 'Not supported';
    }
  }

  /// Checks whether the user toggled on biometric login in settings
  Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledPrefKey) ?? false;
  }

  /// Save whether biometric login is enabled
  Future<void> setBiometricLoginEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledPrefKey, enabled);
    if (!enabled) {
      await clearSavedCredentials();
    }
  }

  /// Securely save credentials for biometric auto-login
  Future<void> saveCredentialsForBiometric({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _savedEmailKey, value: email);
    await _storage.write(key: _savedPasswordKey, value: password);
  }

  /// Retrieve saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    final email = await _storage.read(key: _savedEmailKey);
    final password = await _storage.read(key: _savedPasswordKey);
    if (email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  /// Clear saved biometric credentials
  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: _savedEmailKey);
    await _storage.delete(key: _savedPasswordKey);
  }

  /// Prompts user with Face ID / Fingerprint prompt
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to log in to Imoscan',
  }) async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      return authenticated;
    } on PlatformException catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }
}
