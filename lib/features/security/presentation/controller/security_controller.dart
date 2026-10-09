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
  final SecurityStore _store;
  final ApiClient _api;

  SecurityController({SecurityStore? store, ApiClient? api})
    : _store = store ?? SecurityStore(),
      _api = api ?? ApiClient(baseUrl);

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
            hasAuthenticator: data['hasAuthenticator'] == true,
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
        final current = await describeCurrentDevice();
        final devRes = await _api.get(
          SecurityEndpoints.devices,
          query: {'deviceId': current.id},
        );
        if (devRes.statusCode == 200 &&
            devRes.data != null &&
            devRes.data['data'] != null) {
          final list = devRes.data['data'] as List<dynamic>;
          final serverDevices = [
            for (final item in list)
              LoginDevice.fromJson(item as Map<String, dynamic>),
          ];
          devices.value = serverDevices;
          await _store.writeDevices(serverDevices);
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

  Future<bool> setEnabled(bool enabled) async {
    try {
      final response = await _api.patch(
        SecurityEndpoints.toggleTwoFactor,
        data: {'enabled': enabled},
      );
      if (response.data['success'] != true) return false;
      settings.value = settings.value.copyWith(enabled: enabled);
      await _store.writeSettings(settings.value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setMethod(TwoFactorMethod method) async {
    try {
      final response = await _api.patch(
        SecurityEndpoints.setMethod,
        data: {'method': method.name},
      );
      if (response.data['success'] != true) return false;
      settings.value = settings.value.copyWith(method: method);
      await _store.writeSettings(settings.value);
      return true;
    } catch (_) {
      return false;
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

    try {
      final response = await _api.post(
        SecurityEndpoints.authenticatorConfirm,
        data: {'secret': secret, 'code': code},
      );
      if (response.data['success'] != true ||
          response.data['data']?['success'] != true) {
        return false;
      }
      settings.value = settings.value.copyWith(
        enabled: true,
        method: TwoFactorMethod.authenticator,
        hasAuthenticator: true,
        clearAuthenticatorSecret: true,
      );
      await _store.writeSettings(settings.value);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeAuthenticator() async {
    try {
      final response = await _api.delete(SecurityEndpoints.removeAuthenticator);
      if (response.data['success'] != true) return false;
      settings.value = settings.value.copyWith(
        clearAuthenticatorSecret: true,
        hasAuthenticator: false,
        method: response.data['data']?['method'] == 'sms'
            ? TwoFactorMethod.sms
            : TwoFactorMethod.email,
      );
      await _store.writeSettings(settings.value);
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------------- challenges

  /// Reports success only when the server confirms actual delivery.
  Future<ChallengeDispatch> sendChallenge({
    required TwoFactorMethod method,
    required String destination,
  }) async {
    try {
      final response = await _api.post(
        SecurityEndpoints.sendChallenge,
        data: {'method': method.name},
      );
      final data = response.data['data'];
      return ChallengeDispatch(
        sent: response.data['success'] == true && data?['sent'] == true,
        destination: data?['destination']?.toString() ?? destination,
      );
    } catch (_) {
      return ChallengeDispatch(sent: false, destination: destination);
    }
  }

  /// The server verifies its configured secret, including on a new device.
  /// An HTTP success or local cached secret alone cannot authorize a code.
  Future<bool> verifyChallenge(String code, {String? email}) async {
    final trimmed = code.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) return false;
    try {
      final response = await _api.post(
        SecurityEndpoints.verifyChallenge,
        data: {'code': trimmed},
      );
      return response.data['success'] == true &&
          response.data['data']?['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------------ devices

  /// Describes the device this install is running on.
  Future<LoginDevice> describeCurrentDevice() async {
    var id = await _store.readTrustedDeviceId();
    if (id == null || id.isEmpty) {
      id =
          'dev_${DateTime.now().millisecondsSinceEpoch}_'
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
  Future<bool> registerCurrentDevice() async {
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
    try {
      final response = await _api.post(
        SecurityEndpoints.registerDevice,
        data: {
          'deviceId': current.id,
          'name': current.name,
          'platform': current.platform,
          'location': current.location,
        },
      );
      if (response.data is! Map ||
          response.data['success'] != true ||
          response.data['data'] is! Map ||
          response.data['data']['deviceId'] != current.id) {
        return false;
      }
      devices.value = next;
      await _store.writeDevices(next);
      return true;
    } catch (e) {
      debugPrint('Could not register device with server: $e');
      return false;
    }
  }

  /// Revokes a device from settings. The current device is never removable
  /// here — signing out is the way to end this session.
  Future<bool> removeDevice(String deviceId) async {
    final target = devices.firstWhereOrNull((device) => device.id == deviceId);
    if (target == null || target.isCurrent) return false;

    try {
      final response = await _api.delete(
        SecurityEndpoints.removeDevice(deviceId),
      );
      final data = response.data;
      if (data is! Map ||
          data['success'] != true ||
          data['data'] is! Map ||
          data['data']['removed'] != true) {
        return false;
      }
      devices.removeWhere((device) => device.id == deviceId);
      await _store.writeDevices(devices);
      return true;
    } catch (e) {
      debugPrint('Could not remove device on server: $e');
      return false;
    }
  }

  // ----------------------------------------------------- new-device approval

  Future<void> raiseNewDeviceRequest(NewDeviceRequest request) async {
    pendingRequest.value = request;
    await _store.writePendingRequest(request);
  }

  Future<bool> approvePendingRequest() async {
    if (!await registerCurrentDevice()) return false;
    pendingRequest.value = null;
    await _store.writePendingRequest(null);
    return true;
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
