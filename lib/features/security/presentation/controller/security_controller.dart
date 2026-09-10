import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/security_store.dart';
import '../../domain/security_models.dart';
import '../../domain/totp.dart';

/// Result of asking for a challenge code to be sent.
class ChallengeDispatch {
  final bool sent;
  final String destination;

  /// Populated only in debug builds, where there is no mail/SMS gateway to
  /// deliver the code — it lets the flow be walked end to end on device. It is
  /// always null in release.
  final String? debugCode;

  const ChallengeDispatch({
    required this.sent,
    required this.destination,
    this.debugCode,
  });
}

/// Owns two-factor settings, the device list and the sign-in challenges.
class SecurityController extends GetxController {
  final SecurityStore _store = SecurityStore();

  final settings = const TwoFactorSettings().obs;
  final devices = <LoginDevice>[].obs;
  final pendingRequest = Rx<NewDeviceRequest?>(null);
  final isLoading = false.obs;

  static SecurityController get instance {
    if (!Get.isRegistered<SecurityController>()) {
      Get.put(SecurityController(), permanent: true);
    }
    return Get.find<SecurityController>();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      settings.value = await _store.readSettings();
      devices.value = await _store.readDevices();
      pendingRequest.value = await _store.readPendingRequest();
    } finally {
      isLoading.value = false;
    }
  }

  int get deviceCount => devices.length;

  // ---------------------------------------------------------------- settings

  Future<void> setEnabled(bool enabled) async {
    settings.value = settings.value.copyWith(enabled: enabled);
    await _store.writeSettings(settings.value);
  }

  Future<void> setMethod(TwoFactorMethod method) async {
    settings.value = settings.value.copyWith(method: method);
    await _store.writeSettings(settings.value);
  }

  Future<void> setEmailVerified(bool value) async {
    settings.value = settings.value.copyWith(emailVerified: value);
    await _store.writeSettings(settings.value);
  }

  Future<void> setPhoneVerified(bool value) async {
    settings.value = settings.value.copyWith(phoneVerified: value);
    await _store.writeSettings(settings.value);
  }

  /// Creates a secret for the authenticator app. The caller shows it as a QR
  /// code / setup key and must confirm a generated code before it is kept.
  String startAuthenticatorSetup() => Totp.generateSecret();

  /// Confirms the authenticator setup with a code from the app, and only then
  /// stores the secret and switches the method over.
  Future<bool> confirmAuthenticatorSetup({
    required String secret,
    required String code,
  }) async {
    if (!Totp.verify(secret, code)) return false;

    settings.value = settings.value.copyWith(
      enabled: true,
      method: TwoFactorMethod.authenticator,
      authenticatorSecret: secret,
    );
    await _store.writeSettings(settings.value);
    return true;
  }

  Future<void> removeAuthenticator() async {
    final next = settings.value.copyWith(
      clearAuthenticatorSecret: true,
      method: settings.value.emailVerified
          ? TwoFactorMethod.email
          : TwoFactorMethod.sms,
    );
    settings.value = next;
    await _store.writeSettings(next);
  }

  // -------------------------------------------------------------- challenges

  /// Issues a one-time code for [method] and records only its salted hash.
  ///
  /// Delivery itself is the backend's job — there is no mail or SMS gateway in
  /// the app. Until those routes exist the code is surfaced in debug builds so
  /// the flow can be exercised; release builds never expose it.
  Future<ChallengeDispatch> sendChallenge({
    required TwoFactorMethod method,
    required String destination,
  }) async {
    final code = OneTimeCode.generate();
    final salt = OneTimeCode.newSalt();

    await _store.writeChallenge({
      'hash': OneTimeCode.hash(code, salt),
      'salt': salt,
      'method': method.name,
      'destination': destination,
      'expiresAt': DateTime.now().add(OneTimeCode.validity).toIso8601String(),
      'attempts': 0,
    });

    return ChallengeDispatch(
      sent: true,
      destination: destination,
      debugCode: kReleaseMode ? null : code,
    );
  }

  /// Verifies a code against whichever challenge is live.
  ///
  /// Authenticator codes are checked against the stored secret; email and SMS
  /// codes against the hash written by [sendChallenge]. Five wrong attempts
  /// burn the challenge, so a code cannot be brute-forced.
  Future<bool> verifyChallenge(String code) async {
    final trimmed = code.replaceAll(RegExp(r'\s'), '');

    final secret = settings.value.authenticatorSecret;
    if (settings.value.method == TwoFactorMethod.authenticator &&
        secret != null &&
        secret.isNotEmpty) {
      return Totp.verify(secret, trimmed);
    }

    final challenge = await _store.readChallenge();
    if (challenge == null) return false;

    final expiresAt = DateTime.tryParse(
      challenge['expiresAt']?.toString() ?? '',
    );
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      await _store.writeChallenge(null);
      return false;
    }

    final attempts = (challenge['attempts'] as num?)?.toInt() ?? 0;
    if (attempts >= 5) {
      await _store.writeChallenge(null);
      return false;
    }

    final matched = OneTimeCode.matches(
      code: trimmed,
      salt: challenge['salt']?.toString() ?? '',
      storedHash: challenge['hash']?.toString() ?? '',
    );

    if (matched) {
      await _store.writeChallenge(null);
      return true;
    }

    challenge['attempts'] = attempts + 1;
    await _store.writeChallenge(challenge);
    return false;
  }

  // ------------------------------------------------------------------ devices

  /// Describes the device this install is running on.
  Future<LoginDevice> describeCurrentDevice() async {
    var id = await _store.readTrustedDeviceId();
    if (id == null || id.isEmpty) {
      id = 'dev_${DateTime.now().millisecondsSinceEpoch}_'
          '${Random.secure().nextInt(0xffff)}';
      await _store.writeTrustedDeviceId(id);
    }

    var name = 'This device';
    var platform = defaultTargetPlatform.name;

    try {
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        name = ios.name.isNotEmpty ? ios.name : ios.utsname.machine;
        platform = 'iOS ${ios.systemVersion}';
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        name = '${android.manufacturer} ${android.model}'.trim();
        platform = 'Android ${android.version.release}';
      }
    } catch (e) {
      // Device naming is cosmetic — a generic label is fine if the plugin
      // is unavailable on this platform.
      debugPrint('Device info unavailable: $e');
    }

    return LoginDevice(
      id: id,
      name: name,
      platform: platform,
      // Coarse only. The privacy rule is explicit that location content is
      // never stored just because the permission exists.
      location: 'Approximate location unavailable',
      lastActive: DateTime.now(),
      isCurrent: true,
    );
  }

  /// True when this install has never been registered on the account, which
  /// is what triggers the New Device Detected screen and the permissions
  /// intro.
  Future<bool> isNewDevice() async {
    final current = await describeCurrentDevice();
    return !devices.any((device) => device.id == current.id);
  }

  /// Records this device as signed in, refreshing its "last active" stamp if
  /// it is already on the list.
  Future<void> registerCurrentDevice() async {
    final current = await describeCurrentDevice();
    final next = [
      for (final device in devices)
        device.id == current.id
            ? device.copyWith(lastActive: DateTime.now(), isCurrent: true)
            : device.copyWith(isCurrent: false),
    ];
    if (!next.any((device) => device.id == current.id)) {
      next.add(current);
    }
    devices.value = next;
    await _store.writeDevices(next);
  }

  /// Revokes a device from settings. The current device is never removable
  /// here — signing out is the way to end this session.
  Future<bool> removeDevice(String deviceId) async {
    final target = devices.firstWhereOrNull((device) => device.id == deviceId);
    if (target == null || target.isCurrent) return false;

    devices.removeWhere((device) => device.id == deviceId);
    await _store.writeDevices(devices);
    return true;
  }

  // ----------------------------------------------------- new-device approval

  Future<void> raiseNewDeviceRequest(NewDeviceRequest request) async {
    pendingRequest.value = request;
    await _store.writePendingRequest(request);
  }

  Future<void> approvePendingRequest() async {
    pendingRequest.value = null;
    await _store.writePendingRequest(null);
    await registerCurrentDevice();
  }

  Future<void> denyPendingRequest() async {
    pendingRequest.value = null;
    await _store.writePendingRequest(null);
  }

  /// Clears every security record, used when the account is deleted.
  Future<void> wipe() async {
    await _store.clear();
    settings.value = const TwoFactorSettings();
    devices.clear();
    pendingRequest.value = null;
  }
}
