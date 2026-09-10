import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../security/domain/totp.dart';
import '../../domain/trade_in_consent.dart';

/// Result of sending the secure link and code to the customer.
class ConsentDispatch {
  final bool sent;
  final String maskedDestination;

  /// Debug builds only: there is no SMS/email gateway in the app yet, so the
  /// code is surfaced to let the flow be walked on a real device. Always null
  /// in release.
  final String? debugCode;

  const ConsentDispatch({
    required this.sent,
    required this.maskedDestination,
    this.debugCode,
  });
}

/// Drives the trade-in customer consent flow and keeps its audit trail.
///
/// The consent record is what unlocks the ID capture and the IMEI scan — the
/// client was explicit that permission is taken *before* anything is
/// photographed or scanned, not after.
class ConsentController extends GetxController {
  static const _storage = FlutterSecureStorage();
  static const _recordsKey = 'trade_in_consents_v1';

  final active = Rx<TradeInConsent?>(null);
  final records = <TradeInConsent>[].obs;

  /// Salted hash of the live code, with its expiry. The code itself is never
  /// written down.
  Map<String, dynamic>? _challenge;

  static ConsentController get instance {
    if (!Get.isRegistered<ConsentController>()) {
      Get.put(ConsentController(), permanent: true);
    }
    return Get.find<ConsentController>();
  }

  @override
  void onInit() {
    super.onInit();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final raw = await _storage.read(key: _recordsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      records.value = [
        for (final item in list)
          TradeInConsent.fromJson(item as Map<String, dynamic>),
      ];
    } catch (e) {
      debugPrint('Could not read consent records: $e');
    }
  }

  Future<void> _persist() async {
    await _storage.write(
      key: _recordsKey,
      value: jsonEncode([for (final record in records) record.toJson()]),
    );
  }

  /// `CN-` plus five digits, matching the reference on the client's approval
  /// screen.
  String _newReference() =>
      'CN-${(10000 + Random.secure().nextInt(89999))}';

  /// Starts a consent request for the customer and item on screen.
  TradeInConsent start({
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String itemName,
    required double agreedValue,
    required String paymentMethod,
    required ConsentChannel channel,
  }) {
    final consent = TradeInConsent(
      reference: _newReference(),
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      itemName: itemName,
      agreedValue: agreedValue,
      paymentMethod: paymentMethod,
      channel: channel,
    );
    active.value = consent;
    return consent;
  }

  /// Sends the secure link and the 6-digit code down [channel].
  Future<ConsentDispatch> sendLinkAndCode() async {
    final consent = active.value;
    if (consent == null) {
      return const ConsentDispatch(sent: false, maskedDestination: '');
    }

    final code = OneTimeCode.generate();
    final salt = OneTimeCode.newSalt();
    _challenge = {
      'hash': OneTimeCode.hash(code, salt),
      'salt': salt,
      'expiresAt': DateTime.now().add(OneTimeCode.validity).toIso8601String(),
      'attempts': 0,
    };

    active.value = consent.copyWith(
      status: ConsentStatus.awaitingVerification,
    );

    return ConsentDispatch(
      sent: true,
      maskedDestination: consent.maskedDestination,
      debugCode: kReleaseMode ? null : code,
    );
  }

  /// Verifies the customer's code. Five wrong tries burn the challenge.
  Future<bool> verifyCode(String input) async {
    final consent = active.value;
    final challenge = _challenge;
    if (consent == null || challenge == null) return false;

    final expiresAt = DateTime.tryParse(
      challenge['expiresAt']?.toString() ?? '',
    );
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      _challenge = null;
      return false;
    }

    final attempts = (challenge['attempts'] as num?)?.toInt() ?? 0;
    if (attempts >= 5) {
      _challenge = null;
      return false;
    }

    final matched = OneTimeCode.matches(
      code: input,
      salt: challenge['salt']?.toString() ?? '',
      storedHash: challenge['hash']?.toString() ?? '',
    );

    if (!matched) {
      challenge['attempts'] = attempts + 1;
      return false;
    }

    _challenge = null;
    active.value = consent.copyWith(
      status: ConsentStatus.verified,
      verifiedAt: DateTime.now(),
    );
    return true;
  }

  /// The customer has read and agreed to the declaration.
  ///
  /// This is the point the ID image retention clock is set: 28 days from
  /// capture, after which the original image is deleted automatically.
  Future<TradeInConsent?> approve() async {
    final consent = active.value;
    if (consent == null || consent.status != ConsentStatus.verified) {
      return null;
    }

    final approved = consent.copyWith(
      status: ConsentStatus.approved,
      approvedAt: DateTime.now(),
      deviceMetadata: await _describeDevice(),
      idImageDeleteAfter: DateTime.now().add(const Duration(days: 28)),
    );

    active.value = approved;
    records.add(approved);
    await _persist();
    return approved;
  }

  Future<void> decline() async {
    final consent = active.value;
    if (consent == null) return;
    active.value = consent.copyWith(status: ConsentStatus.declined);
    _challenge = null;
  }

  /// Clears the in-flight consent. The saved record stays in [records] for the
  /// audit trail.
  void reset() {
    active.value = null;
    _challenge = null;
  }

  /// Any change to the item, value or payment method after approval voids the
  /// consent — the developer notes require fresh consent for that.
  void invalidateOnChange() {
    final consent = active.value;
    if (consent == null || consent.status != ConsentStatus.approved) return;
    active.value = consent.copyWith(status: ConsentStatus.notRequested);
  }

  bool get canCapture => active.value?.allowsCapture ?? false;

  /// Coarse device and session metadata for the audit trail — model and OS
  /// only. No precise location, and nothing that identifies the customer's
  /// own handset.
  Future<String> _describeDevice() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return 'iOS ${ios.systemVersion} • ${ios.utsname.machine}';
      }
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return 'Android ${android.version.release} • ${android.model}';
      }
    } catch (e) {
      debugPrint('Consent device metadata unavailable: $e');
    }
    return defaultTargetPlatform.name;
  }
}
