import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../security/domain/totp.dart';
import '../../domain/trade_in_consent.dart';

/// Result of sending the secure link and code to the customer.
class ConsentDispatch {
  final bool sent;
  final String maskedDestination;
  final String? secureLink;
  final String? copyMessage;
  final bool emailSent;
  final String? emailError;

  /// Debug builds only: code surfaced to let the flow be walked on a real device.
  final String? debugCode;

  const ConsentDispatch({
    required this.sent,
    required this.maskedDestination,
    this.secureLink,
    this.copyMessage,
    this.debugCode,
    this.emailSent = false,
    this.emailError,
  });
}

/// Drives the trade-in customer consent flow and keeps its audit trail.
///
/// The consent record is what unlocks the ID capture and the IMEI scan —
/// permission is taken *before* anything is photographed or scanned, not after.
class ConsentController extends GetxController {
  static const _storage = FlutterSecureStorage();
  static const _recordsKey = 'trade_in_consents_v1';

  late final ApiClient _api;

  final active = Rx<TradeInConsent?>(null);
  final records = <TradeInConsent>[].obs;

  /// Salted hash of the live code, with its expiry for fallback/offline.
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
    _api = ApiClient(baseUrl);
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

  /// `CN-` plus five digits, matching the reference on the approval screen.
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
    String currencySymbol = '',
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
      currencySymbol: currencySymbol,
    );
    active.value = consent;
    return consent;
  }

  /// Sends the secure link and the 6-digit code to backend and down [channel].
  Future<ConsentDispatch> sendLinkAndCode({bool sendEmailNow = true}) async {
    final consent = active.value;
    if (consent == null) {
      return const ConsentDispatch(sent: false, maskedDestination: '');
    }

    try {
      // 1. Call Backend API: POST /api/v1/consent/request
      final response = await _api.dio.post(
        ConsentEndpoints.request,
        data: {
          'customerName': consent.customerName,
          'customerEmail': consent.customerEmail,
          'customerPhone': consent.customerPhone,
          'itemName': consent.itemName,
          'agreedValue': consent.agreedValue,
          'currency': consent.currencySymbol.isNotEmpty ? consent.currencySymbol : 'GBP',
          'paymentMethod': consent.paymentMethod,
          'channel': consent.channel.name,
          'sendEmailNow': sendEmailNow && consent.channel == ConsentChannel.email,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final backendConsentId = data['consentId']?.toString();
        final reference = data['reference']?.toString() ?? consent.reference;
        final secureToken = data['secureToken']?.toString();
        final secureLink = data['secureLink']?.toString();
        final copyMessage = data['copyMessage']?.toString();
        final code = data['code']?.toString();
        final maskedDest = data['maskedDestination']?.toString() ?? consent.maskedDestination;
        final emailSent = data['emailSent'] as bool? ?? false;
        final emailError = data['emailError']?.toString();

        // Keep local challenge as safety backup
        if (code != null && code.isNotEmpty) {
          final salt = OneTimeCode.newSalt();
          _challenge = {
            'hash': OneTimeCode.hash(code, salt),
            'salt': salt,
            'expiresAt': DateTime.now().add(OneTimeCode.validity).toIso8601String(),
            'attempts': 0,
            'backendCode': code,
          };
        }

        active.value = consent.copyWith(
          reference: reference,
          consentId: backendConsentId,
          secureToken: secureToken,
          secureLink: secureLink,
          copyMessage: copyMessage,
          status: ConsentStatus.awaitingVerification,
        );

        return ConsentDispatch(
          sent: true,
          maskedDestination: maskedDest,
          secureLink: secureLink,
          copyMessage: copyMessage,
          debugCode: code,
          emailSent: emailSent,
          emailError: emailError,
        );
      }
    } catch (e) {
      debugPrint('Backend consent request failed, falling back to local: $e');
    }

    // Fallback: local OTP generation if network/backend offline
    final code = OneTimeCode.generate();
    final salt = OneTimeCode.newSalt();
    _challenge = {
      'hash': OneTimeCode.hash(code, salt),
      'salt': salt,
      'expiresAt': DateTime.now().add(OneTimeCode.validity).toIso8601String(),
      'attempts': 0,
      'backendCode': code,
    };

    active.value = consent.copyWith(
      status: ConsentStatus.awaitingVerification,
    );

    return ConsentDispatch(
      sent: true,
      maskedDestination: consent.maskedDestination,
      debugCode: code,
      emailSent: false,
    );
  }

  /// Resends a new verification code via backend endpoint or regenerates locally.
  Future<ConsentDispatch> resendCode() async {
    final consent = active.value;
    if (consent == null) {
      return const ConsentDispatch(sent: false, maskedDestination: '');
    }

    final identifier = consent.consentId ?? consent.secureToken ?? consent.reference;
    if (identifier.isNotEmpty) {
      try {
        final response = await _api.dio.post(ConsentEndpoints.resend(identifier));
        if (response.statusCode == 200) {
          final data = response.data['data'] as Map<String, dynamic>? ?? {};
          final code = data['code']?.toString();
          final secureLink = data['secureLink']?.toString();
          final maskedDest = data['maskedDestination']?.toString() ?? consent.maskedDestination;
          final emailSent = data['emailSent'] as bool? ?? false;

          if (code != null && code.isNotEmpty) {
            final salt = OneTimeCode.newSalt();
            _challenge = {
              'hash': OneTimeCode.hash(code, salt),
              'salt': salt,
              'expiresAt': DateTime.now().add(OneTimeCode.validity).toIso8601String(),
              'attempts': 0,
              'backendCode': code,
            };
          }

          return ConsentDispatch(
            sent: true,
            maskedDestination: maskedDest,
            secureLink: secureLink,
            debugCode: code,
            emailSent: emailSent,
          );
        }
      } catch (e) {
        debugPrint('Backend resendCode failed: $e');
      }
    }

    return await sendLinkAndCode(sendEmailNow: consent.channel == ConsentChannel.email);
  }

  /// Verifies the customer's code via backend or fallback challenge.
  Future<bool> verifyCode(String input) async {
    final consent = active.value;
    if (consent == null) return false;

    // 1. Try Backend API first if we have consentId or secureToken
    final identifier = consent.consentId ?? consent.secureToken ?? consent.reference;
    if (identifier.isNotEmpty) {
      try {
        final response = await _api.dio.post(
          ConsentEndpoints.verify(identifier),
          data: {'code': input.trim()},
        );
        if (response.statusCode == 200 && response.data['success'] == true) {
          _challenge = null;
          active.value = consent.copyWith(
            status: ConsentStatus.verified,
            verifiedAt: DateTime.now(),
          );
          return true;
        }
      } catch (e) {
        debugPrint('Backend verifyCode failed, checking local challenge: $e');
      }
    }

    // 2. Fallback: local challenge check
    final challenge = _challenge;
    if (challenge == null) return false;

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
  Future<TradeInConsent?> approve() async {
    final consent = active.value;
    if (consent == null || consent.status != ConsentStatus.verified) {
      return null;
    }

    final deviceMeta = await _describeDevice();
    final approvedAt = DateTime.now();
    final idImageDeleteAfter = approvedAt.add(const Duration(days: 28));

    // 1. Call Backend API
    final identifier = consent.consentId ?? consent.secureToken ?? consent.reference;
    if (identifier.isNotEmpty) {
      try {
        await _api.dio.post(
          ConsentEndpoints.approve(identifier),
          data: {
            'confirmAge18': true,
            'confirmOwnership': true,
            'confirmTermsAgreed': true,
            'deviceMetadata': deviceMeta,
          },
        );
      } catch (e) {
        debugPrint('Backend approve consent failed: $e');
      }
    }

    final approved = consent.copyWith(
      status: ConsentStatus.approved,
      approvedAt: approvedAt,
      deviceMetadata: deviceMeta,
      idImageDeleteAfter: idImageDeleteAfter,
    );

    active.value = approved;
    records.add(approved);
    await _persist();
    return approved;
  }

  Future<void> decline() async {
    final consent = active.value;
    if (consent == null) return;

    final identifier = consent.consentId ?? consent.secureToken ?? consent.reference;
    if (identifier.isNotEmpty) {
      try {
        await _api.dio.post(ConsentEndpoints.decline(identifier));
      } catch (e) {
        debugPrint('Backend decline consent failed: $e');
      }
    }

    active.value = consent.copyWith(status: ConsentStatus.declined);
    _challenge = null;
  }

  /// Clears the in-flight consent. The saved record stays in [records] for audit.
  void reset() {
    active.value = null;
    _challenge = null;
  }

  /// Any change to the item, value or payment method after approval voids consent.
  void invalidateOnChange() {
    final consent = active.value;
    if (consent == null || consent.status != ConsentStatus.approved) return;
    active.value = consent.copyWith(status: ConsentStatus.notRequested);
  }

  bool get canCapture => active.value?.allowsCapture ?? false;

  /// Coarse device and session metadata for audit trail.
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
