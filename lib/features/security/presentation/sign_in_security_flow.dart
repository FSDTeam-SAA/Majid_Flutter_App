import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../privacy/presentation/pages/permissions_intro_page.dart';
import '../../profile/presentation/controller/profile_controller.dart';
import '../domain/security_models.dart';
import 'controller/security_controller.dart';
import 'pages/new_device_page.dart';
import 'pages/two_factor_challenge_page.dart';

/// Everything that has to happen between a correct password and the app
/// opening, in the order the client set out:
///
/// 1. if two-factor is on, ask for a code (authenticator, email or SMS);
/// 2. if the device has never been seen, let the owner approve or deny it;
/// 3. on a genuinely new device only, show the permissions screen once.
///
/// Returns false when the shopkeeper backed out or denied the device, in
/// which case the caller must not let them through.
abstract final class SignInSecurityFlow {
  static Future<bool> run(BuildContext context) async {
    final security = SecurityController.instance;
    await security.load();

    final profile = Get.find<ProfileController>();
    if (profile.userId.isEmpty) {
      // The challenge screens need the registered email and phone to say
      // where a code was sent.
      await profile.fetchProfile();
    }

    final settings = security.settings.value;
    final isNewDevice = await security.isNewDevice();

    if (!context.mounted) return false;

    // 1. Two-factor code.
    if (settings.enabled) {
      final verified = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => TwoFactorChallengePage(
            settings: settings,
            email: profile.email,
            phone: profile.phone,
          ),
        ),
      );
      if (verified != true) return false;
    }

    if (!context.mounted) return false;

    // 2. New device approval.
    if (isNewDevice) {
      final current = await security.describeCurrentDevice();
      final request = NewDeviceRequest(
        id: current.id,
        deviceName: current.name,
        platform: current.platform,
        location: current.location,
        requestedAt: DateTime.now(),
      );
      await security.raiseNewDeviceRequest(request);

      if (!context.mounted) return false;
      final approved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => NewDevicePage(request: request)),
      );
      if (approved != true) {
        await security.denyPendingRequest();
        return false;
      }

      // 3. Permissions, once, for this new device only.
      if (!context.mounted) return true;
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PermissionsIntroPage()),
      );
      return true;
    }

    // A device we already know: refresh its "last active" stamp and let it
    // straight through — no permission prompts.
    await security.registerCurrentDevice();
    return true;
  }
}
