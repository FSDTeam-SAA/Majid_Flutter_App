/// How the secure link and 6-digit code reached the customer.
enum ConsentChannel {
  sms(label: 'SMS'),
  email(label: 'Email');

  final String label;

  const ConsentChannel({required this.label});
}

enum ConsentStatus {
  /// Nothing sent yet.
  notRequested,

  /// Link and code sent, waiting for the customer to verify.
  awaitingVerification,

  /// Code entered correctly; the declaration has not been agreed yet.
  verified,

  /// The customer agreed to the terms and privacy notice.
  approved,

  /// The customer declined, or the request was cancelled.
  declined,
}

/// A customer's consent to a trade-in.
///
/// The developer notes ask for the delivery channel, the OTP verification, the
/// approval time, the customer's device metadata, the terms version and a
/// consent reference all to be saved — every one of those is a field here.
///
/// Consent status and payment status are kept separate on purpose: a recorded
/// payment must never be read as consent, or the other way round.
class TradeInConsent {
  /// Human-readable reference shown on the approval screen and the invoice,
  /// e.g. `CN-10482`.
  final String reference;

  final String customerName;
  final String customerEmail;
  final String customerPhone;

  /// The item and value the customer agreed to. Locked once approved.
  final String itemName;
  final double agreedValue;
  final String paymentMethod;

  final ConsentChannel channel;
  final ConsentStatus status;

  /// When the code was verified and when the declaration was agreed.
  final DateTime? verifiedAt;
  final DateTime? approvedAt;

  /// Which version of the terms the customer saw.
  final String termsVersion;

  /// Coarse device/session metadata captured at approval, for the audit trail.
  final String deviceMetadata;

  /// When the captured identity-document image must be gone by. The policy is
  /// 28 days from capture, and the shop may delete it sooner.
  final DateTime? idImageDeleteAfter;

  const TradeInConsent({
    required this.reference,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.itemName,
    required this.agreedValue,
    required this.paymentMethod,
    required this.channel,
    this.status = ConsentStatus.notRequested,
    this.verifiedAt,
    this.approvedAt,
    this.termsVersion = '2026-09-07',
    this.deviceMetadata = '',
    this.idImageDeleteAfter,
  });

  /// Only an approved consent unlocks the ID capture and IMEI scan.
  bool get allowsCapture => status == ConsentStatus.approved;

  /// Where the code was sent, masked the way the client's screen shows it
  /// ("•••• 4821") so the full contact detail is not left on screen.
  String get maskedDestination {
    final raw = channel == ConsentChannel.sms ? customerPhone : customerEmail;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'your saved contact';

    if (channel == ConsentChannel.sms) {
      final digits = trimmed.replaceAll(RegExp(r'\D'), '');
      final tail = digits.length >= 4
          ? digits.substring(digits.length - 4)
          : digits;
      return '•••• $tail';
    }

    final at = trimmed.indexOf('@');
    if (at <= 1) return trimmed;
    final name = trimmed.substring(0, at);
    final visible = name.length <= 2 ? name : name.substring(0, 2);
    return '$visible${'•' * (name.length - visible.length)}${trimmed.substring(at)}';
  }

  TradeInConsent copyWith({
    ConsentStatus? status,
    ConsentChannel? channel,
    DateTime? verifiedAt,
    DateTime? approvedAt,
    String? deviceMetadata,
    DateTime? idImageDeleteAfter,
  }) => TradeInConsent(
    reference: reference,
    customerName: customerName,
    customerEmail: customerEmail,
    customerPhone: customerPhone,
    itemName: itemName,
    agreedValue: agreedValue,
    paymentMethod: paymentMethod,
    channel: channel ?? this.channel,
    status: status ?? this.status,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    approvedAt: approvedAt ?? this.approvedAt,
    termsVersion: termsVersion,
    deviceMetadata: deviceMetadata ?? this.deviceMetadata,
    idImageDeleteAfter: idImageDeleteAfter ?? this.idImageDeleteAfter,
  );

  Map<String, dynamic> toJson() => {
    'reference': reference,
    'customerName': customerName,
    'customerEmail': customerEmail,
    'customerPhone': customerPhone,
    'itemName': itemName,
    'agreedValue': agreedValue,
    'paymentMethod': paymentMethod,
    'channel': channel.name,
    'status': status.name,
    'verifiedAt': verifiedAt?.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'termsVersion': termsVersion,
    'deviceMetadata': deviceMetadata,
    'idImageDeleteAfter': idImageDeleteAfter?.toIso8601String(),
  };

  factory TradeInConsent.fromJson(Map<String, dynamic> json) => TradeInConsent(
    reference: json['reference']?.toString() ?? '',
    customerName: json['customerName']?.toString() ?? '',
    customerEmail: json['customerEmail']?.toString() ?? '',
    customerPhone: json['customerPhone']?.toString() ?? '',
    itemName: json['itemName']?.toString() ?? '',
    agreedValue: (json['agreedValue'] as num?)?.toDouble() ?? 0,
    paymentMethod: json['paymentMethod']?.toString() ?? '',
    channel: ConsentChannel.values.firstWhere(
      (value) => value.name == json['channel'],
      orElse: () => ConsentChannel.sms,
    ),
    status: ConsentStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => ConsentStatus.notRequested,
    ),
    verifiedAt: DateTime.tryParse(json['verifiedAt']?.toString() ?? ''),
    approvedAt: DateTime.tryParse(json['approvedAt']?.toString() ?? ''),
    termsVersion: json['termsVersion']?.toString() ?? '2026-09-07',
    deviceMetadata: json['deviceMetadata']?.toString() ?? '',
    idImageDeleteAfter: DateTime.tryParse(
      json['idImageDeleteAfter']?.toString() ?? '',
    ),
  );
}
