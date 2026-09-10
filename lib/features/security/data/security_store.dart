import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/security_models.dart';

/// Persistence for the account-security state.
///
/// It lives in [FlutterSecureStorage] (Keychain / EncryptedSharedPreferences)
/// because it holds the authenticator secret and the hashed challenge codes.
///
/// The backend has no two-factor or device-session routes yet. Everything the
/// UI needs is stored here so the flows are complete and testable on device;
/// when the server endpoints land, only this class needs to change — the
/// controller and every screen talk to it, not to storage directly.
class SecurityStore {
  static const _storage = FlutterSecureStorage();

  static const _settingsKey = 'security_two_factor_settings_v1';
  static const _devicesKey = 'security_login_devices_v1';
  static const _pendingRequestKey = 'security_pending_device_request_v1';
  static const _challengeKey = 'security_active_challenge_v1';
  static const _trustedDeviceKey = 'security_trusted_device_id_v1';

  Future<TwoFactorSettings> readSettings() async {
    final raw = await _storage.read(key: _settingsKey);
    if (raw == null || raw.isEmpty) return const TwoFactorSettings();
    try {
      return TwoFactorSettings.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Could not read two-factor settings: $e');
      return const TwoFactorSettings();
    }
  }

  Future<void> writeSettings(TwoFactorSettings settings) =>
      _storage.write(key: _settingsKey, value: jsonEncode(settings.toJson()));

  Future<List<LoginDevice>> readDevices() async {
    final raw = await _storage.read(key: _devicesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          LoginDevice.fromJson(item as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('Could not read login devices: $e');
      return [];
    }
  }

  Future<void> writeDevices(List<LoginDevice> devices) => _storage.write(
    key: _devicesKey,
    value: jsonEncode([for (final device in devices) device.toJson()]),
  );

  Future<NewDeviceRequest?> readPendingRequest() async {
    final raw = await _storage.read(key: _pendingRequestKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return NewDeviceRequest.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Could not read pending device request: $e');
      return null;
    }
  }

  Future<void> writePendingRequest(NewDeviceRequest? request) async {
    if (request == null) {
      await _storage.delete(key: _pendingRequestKey);
      return;
    }
    await _storage.write(
      key: _pendingRequestKey,
      value: jsonEncode(request.toJson()),
    );
  }

  /// The live email/SMS challenge: its hash, salt and expiry only. The code
  /// itself is never written down.
  Future<Map<String, dynamic>?> readChallenge() async {
    final raw = await _storage.read(key: _challengeKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Could not read active challenge: $e');
      return null;
    }
  }

  Future<void> writeChallenge(Map<String, dynamic>? challenge) async {
    if (challenge == null) {
      await _storage.delete(key: _challengeKey);
      return;
    }
    await _storage.write(key: _challengeKey, value: jsonEncode(challenge));
  }

  /// Id of the device this install represents, so a returning device is not
  /// treated as new on every launch.
  Future<String?> readTrustedDeviceId() =>
      _storage.read(key: _trustedDeviceKey);

  Future<void> writeTrustedDeviceId(String id) =>
      _storage.write(key: _trustedDeviceKey, value: id);

  /// Wipes every security record. Used when the account is deleted.
  Future<void> clear() async {
    await _storage.delete(key: _settingsKey);
    await _storage.delete(key: _devicesKey);
    await _storage.delete(key: _pendingRequestKey);
    await _storage.delete(key: _challengeKey);
    await _storage.delete(key: _trustedDeviceKey);
  }
}
