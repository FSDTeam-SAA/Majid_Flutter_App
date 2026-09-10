/// How a two-factor challenge is delivered.
enum TwoFactorMethod {
  authenticator(
    label: 'Authenticator app',
    description: 'A new 6-digit code every 30 seconds',
  ),
  email(label: 'Email', description: 'Send a code to your registered email'),
  sms(label: 'Text message', description: 'Send a code to your registered number');

  final String label;
  final String description;

  const TwoFactorMethod({required this.label, required this.description});
}

/// A device that has signed in to this account.
///
/// The client asked to "see from settings how many devices are connected
/// currently and let them delete if they want", so every field here exists to
/// make a row identifiable enough to revoke with confidence.
class LoginDevice {
  final String id;
  final String name;
  final String platform;

  /// Coarse location ("London, United Kingdom") — never a precise position.
  final String location;
  final DateTime lastActive;

  /// True for the device the app is running on, which cannot be removed from
  /// here (you sign out instead).
  final bool isCurrent;

  const LoginDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.location,
    required this.lastActive,
    this.isCurrent = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'platform': platform,
    'location': location,
    'lastActive': lastActive.toIso8601String(),
    'isCurrent': isCurrent,
  };

  factory LoginDevice.fromJson(Map<String, dynamic> json) => LoginDevice(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Unknown device',
    platform: json['platform']?.toString() ?? '',
    location: json['location']?.toString() ?? 'Unknown location',
    lastActive:
        DateTime.tryParse(json['lastActive']?.toString() ?? '') ??
        DateTime.now(),
    isCurrent: json['isCurrent'] == true,
  );

  LoginDevice copyWith({DateTime? lastActive, bool? isCurrent}) => LoginDevice(
    id: id,
    name: name,
    platform: platform,
    location: location,
    lastActive: lastActive ?? this.lastActive,
    isCurrent: isCurrent ?? this.isCurrent,
  );
}

/// A sign-in attempt from a device the account has not seen before.
///
/// The owner approves or denies it from the push notification, from an email
/// link, or from a code sent to their number — the three routes the client
/// listed.
class NewDeviceRequest {
  final String id;
  final String deviceName;
  final String platform;
  final String location;
  final DateTime requestedAt;

  const NewDeviceRequest({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.location,
    required this.requestedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceName': deviceName,
    'platform': platform,
    'location': location,
    'requestedAt': requestedAt.toIso8601String(),
  };

  factory NewDeviceRequest.fromJson(Map<String, dynamic> json) =>
      NewDeviceRequest(
        id: json['id']?.toString() ?? '',
        deviceName: json['deviceName']?.toString() ?? 'Unknown device',
        platform: json['platform']?.toString() ?? '',
        location: json['location']?.toString() ?? 'Unknown location',
        requestedAt:
            DateTime.tryParse(json['requestedAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}

/// The account's two-factor configuration.
class TwoFactorSettings {
  final bool enabled;
  final TwoFactorMethod method;

  /// Present only once the authenticator option has been set up.
  final String? authenticatorSecret;
  final bool emailVerified;
  final bool phoneVerified;

  const TwoFactorSettings({
    this.enabled = false,
    this.method = TwoFactorMethod.email,
    this.authenticatorSecret,
    this.emailVerified = false,
    this.phoneVerified = false,
  });

  bool get isConfirmed => emailVerified || phoneVerified;

  TwoFactorSettings copyWith({
    bool? enabled,
    TwoFactorMethod? method,
    String? authenticatorSecret,
    bool clearAuthenticatorSecret = false,
    bool? emailVerified,
    bool? phoneVerified,
  }) => TwoFactorSettings(
    enabled: enabled ?? this.enabled,
    method: method ?? this.method,
    authenticatorSecret: clearAuthenticatorSecret
        ? null
        : (authenticatorSecret ?? this.authenticatorSecret),
    emailVerified: emailVerified ?? this.emailVerified,
    phoneVerified: phoneVerified ?? this.phoneVerified,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'method': method.name,
    'authenticatorSecret': authenticatorSecret,
    'emailVerified': emailVerified,
    'phoneVerified': phoneVerified,
  };

  factory TwoFactorSettings.fromJson(Map<String, dynamic> json) =>
      TwoFactorSettings(
        enabled: json['enabled'] == true,
        method: TwoFactorMethod.values.firstWhere(
          (value) => value.name == json['method'],
          orElse: () => TwoFactorMethod.email,
        ),
        authenticatorSecret: json['authenticatorSecret']?.toString(),
        emailVerified: json['emailVerified'] == true,
        phoneVerified: json['phoneVerified'] == true,
      );
}
