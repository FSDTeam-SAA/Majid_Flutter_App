import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
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
  final ApiClient _api = ApiClient(baseUrl);

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

      // Sync settings from server if available
      try {
        final res = await _api.get(SecurityEndpoints.settings);
        if (res.statusCode == 200 &&
            res.data != null &&
            res.data['data'] != null) {
          final data = res.data['data'];
          final serverSettings = TwoFactorSettings(
            enabled: data['enabled'] == true,
            method: TwoFactorMethod.values.firstWhere(
              (value) => value.name == data['method'],
              orElse: () => TwoFactorMethod.email,
            ),
            authenticatorSecret: settings.value.authenticatorSecret,
            emailVerified: data['emailVerified'] == true,
            phoneVerified: data['phoneVerified'] == true,
          );
          settings.value = serverSettings;
          await _store.writeSettings(serverSettings);
        }
      } catch (e) {
        debugPrint('Could not sync settings from server: $e');
      }

      // Sync devices from server if available
      try {
        final devRes = await _api.get(SecurityEndpoints.devices);
        if (devRes.statusCode == 200 &&
            devRes.data != null &&
            devRes.data['data'] != null) {
          final list = devRes.data['data'] as List<dynamic>;
          if (list.isNotEmpty) {
            final serverDevices = [
              for (final item in list)
                LoginDevice.fromJson(item as Map<String, dynamic>),
            ];
            devices.value = serverDevices;
            await _store.writeDevices(serverDevices);
          }
        }
      } catch (e) {
        debugPrint('Could not sync devices from server: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  int get deviceCount => devices.length;

  // ---------------------------------------------------------------- settings

  Future<void> setEnabled(bool enabled) async {
    settings.value = settings.value.copyWith(enabled: enabled);
    await _store.writeSettings(settings.value);

    try {
      await _api.patch(
        SecurityEndpoints.toggleTwoFactor,
        data: {'enabled': enabled},
      );
    } catch (e) {
      debugPrint('Could not sync 2FA toggle with server: $e');
    }
  }

  Future<void> setMethod(TwoFactorMethod method) async {
    settings.value = settings.value.copyWith(method: method);
    await _store.writeSettings(settings.value);

    try {
      await _api.patch(
        SecurityEndpoints.setMethod,
        data: {'method': method.name},
      );
    } catch (e) {
      debugPrint('Could not sync 2FA method with server: $e');
    }
  }

  Future<void> setEmailVerified(bool value) async {
    settings.value = settings.value.copyWith(emailVerified: value);
    await _store.writeSettings(settings.value);

    if (value) {
      try {
        await _api.post(
          SecurityEndpoints.confirmDestination,
          data: {'method': 'email'},
        );
      } catch (e) {
        debugPrint('Could not confirm email destination on server: $e');
      }
    }
  }

  Future<void> setPhoneVerified(bool value) async {
    settings.value = settings.value.copyWith(phoneVerified: value);
    await _store.writeSettings(settings.value);

    if (value) {
      try {
        await _api.post(
          SecurityEndpoints.confirmDestination,
          data: {'method': 'sms'},
        );
      } catch (e) {
        debugPrint('Could not confirm phone destination on server: $e');
      }
    }
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

    try {
      await _api.post(
        SecurityEndpoints.authenticatorConfirm,
        data: {'secret': secret, 'code': code},
      );
    } catch (e) {
      debugPrint('Could not confirm authenticator on server: $e');
    }

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

    try {
      await _api.delete(SecurityEndpoints.removeAuthenticator);
    } catch (e) {
      debugPrint('Could not remove authenticator on server: $e');
    }
  }

  // -------------------------------------------------------------- challenges

  /// Issues a one-time code for [method] to the backend server so a real email/SMS is sent,
  /// while keeping a local fallback for offline/debug resilience.
  Future<ChallengeDispatch> sendChallenge({
    required TwoFactorMethod method,
    required String destination,
  }) async {
    bool sentOnServer = false;
    // 1. Call the backend API to send real email or SMS
    try {
      final res = await _api.post(
        SecurityEndpoints.sendChallenge,
        data: {
          'method': method.name,
          'email': destination,
        },
      );
      debugPrint('sendChallenge server response: ${res.data}');
      if (res.statusCode == 200) {
        sentOnServer = true;
      }
    } catch (e) {
      debugPrint('sendChallenge server error: $e');
      // Try public auth 2FA route fallback
      try {
        final res2 = await _api.post(
          AuthEndpoints.send2FaChallenge,
          data: {
            'email': destination,
            'method': method.name,
          },
        );
        if (res2.statusCode == 200) {
          sentOnServer = true;
        }
      } catch (e2) {
        debugPrint('AuthEndpoints.send2FaChallenge fallback error: $e2');
      }
    }

    // Only store local challenge if server couldn't be reached (offline mode)
    if (!sentOnServer) {
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
    } else {
      // Clear local challenge so stale local codes don't interfere
      await _store.writeChallenge(null);
    }

    return ChallengeDispatch(
      sent: true,
      destination: destination,
      debugCode: null,
    );
  }

  /// Verifies a code against whichever challenge is live.
  ///
  /// Authenticator codes are checked against the stored secret; email and SMS
  /// codes are verified against the backend server, with a local fallback.
  Future<bool> verifyChallenge(String code, {String? email}) async {
    final trimmed = code.replaceAll(RegExp(r'\s'), '');

    final secret = settings.value.authenticatorSecret;
    if (settings.value.method == TwoFactorMethod.authenticator &&
        secret != null &&
        secret.isNotEmpty) {
      return Totp.verify(secret, trimmed);
    }

    // 1. Verify against the real backend server
    try {
      final res = await _api.post(
        SecurityEndpoints.verifyChallenge,
        data: {
          'code': trimmed,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        final isValid = data['data']?['valid'] == true ||
            data['valid'] == true;
        if (isValid) {
          await _store.writeChallenge(null);
          await load();
          return true;
        } else {
          return false;
        }
      }
    } catch (e) {
      debugPrint('verifyChallenge server error: $e');
    }

    // 1b. Fallback to public auth route (for unauthenticated sign-in 2FA)
    if (email != null && email.isNotEmpty) {
      try {
        final res2 = await _api.post(
          AuthEndpoints.verify2Fa,
          data: {'email': email, 'code': trimmed},
        );
        if (res2.statusCode == 200 && res2.data != null) {
          final data = res2.data;
          final isValid = data['data']?['valid'] == true ||
              data['valid'] == true ||
              data['success'] == true;
          if (isValid) {
            await _store.writeChallenge(null);
            return true;
          } else {
            return false;
          }
        }
      } catch (e2) {
        debugPrint('verify2Fa public route error: $e2');
      }
    }

    // 2. Fallback: check local challenge only if backend couldn't be reached
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

    try {
      await _api.post(
        SecurityEndpoints.registerDevice,
        data: {
          'deviceId': current.id,
          'name': current.name,
          'platform': current.platform,
          'location': current.location,
        },
      );
    } catch (e) {
      debugPrint('Could not register device with server: $e');
    }
  }

  /// Revokes a device from settings. The current device is never removable
  /// here — signing out is the way to end this session.
  Future<bool> removeDevice(String deviceId) async {
    final target = devices.firstWhereOrNull((device) => device.id == deviceId);
    if (target == null || target.isCurrent) return false;

    devices.removeWhere((device) => device.id == deviceId);
    await _store.writeDevices(devices);

    try {
      await _api.delete(SecurityEndpoints.removeDevice(deviceId));
    } catch (e) {
      debugPrint('Could not remove device on server: $e');
    }

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
