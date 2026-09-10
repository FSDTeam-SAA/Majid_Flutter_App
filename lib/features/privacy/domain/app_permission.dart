import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// The permissions imoscan actually uses.
///
/// The microphone is deliberately absent: the client asked for that feature to
/// be removed and for the declaration to come out of the iOS and Android
/// manifests, so there is nothing here to request or display.
enum AppPermission {
  camera(
    label: 'Camera',
    purpose: 'IMEI, barcode, ID and repair evidence',
    /// Shown before the OS prompt, so the shopkeeper knows why it is asked.
    rationale:
        'imoscan opens the camera when you scan an IMEI or barcode, capture a '
        'customer ID for a trade-in, or record repair evidence. It is never '
        'opened in the background.',
    grantedLabel: 'Ask When Needed',
    pendingLabel: 'Ask When Needed',
  ),
  photos(
    label: 'Photos',
    purpose: 'Add selected repair or trade-in images',
    rationale:
        'imoscan uses the system photo picker, so only the images you choose '
        'are shared with the app. Full photo-library access is not requested.',
    grantedLabel: 'System Picker',
    pendingLabel: 'System Picker',
  ),
  location(
    label: 'Location',
    purpose: 'Delivery and live tracking only',
    rationale:
        'Location is used only while you are using the app, for delivery and '
        'live order tracking. imoscan never requests Always access.',
    grantedLabel: 'While Using',
    pendingLabel: 'Ask When Needed',
  ),
  notifications(
    label: 'Notifications',
    purpose: 'Orders, repairs and important alerts',
    rationale:
        'Notifications are optional. They carry order, repair and delivery '
        'updates plus account-security alerts such as a new device sign-in.',
    grantedLabel: 'Allowed',
    pendingLabel: 'Ask When Needed',
  ),
  bluetooth(
    label: 'Bluetooth',
    purpose: 'Connect a receipt printer or scanner',
    rationale:
        'Bluetooth is used to pair your receipt printer and barcode scanner. '
        'imoscan does not use it for location or nearby tracking.',
    grantedLabel: 'Allowed',
    pendingLabel: 'Ask When Needed',
  );

  final String label;
  final String purpose;
  final String rationale;

  /// Wording shown when the permission is granted. It describes how imoscan
  /// uses the access rather than just saying "Granted".
  final String grantedLabel;

  /// Wording while it has not been granted but can still be asked for. This is
  /// a normal state, not a fault: imoscan requests in context, so "Ask When
  /// Needed" is the honest description rather than "Not allowed".
  final String pendingLabel;

  const AppPermission({
    required this.label,
    required this.purpose,
    required this.rationale,
    required this.grantedLabel,
    required this.pendingLabel,
  });

  /// The underlying OS permission.
  ///
  /// Bluetooth is the one that differs by platform: `bluetoothConnect` is an
  /// Android 12+ runtime permission and has no iOS strategy at all — asking
  /// for it there falls through to permission_handler's "unknown" strategy and
  /// always reports denied. iOS wants the Core Bluetooth permission instead.
  Permission get handle => switch (this) {
    AppPermission.camera => Permission.camera,
    AppPermission.photos => Permission.photos,
    AppPermission.location => Permission.locationWhenInUse,
    AppPermission.notifications => Permission.notification,
    AppPermission.bluetooth =>
      defaultTargetPlatform == TargetPlatform.android
          ? Permission.bluetoothConnect
          : Permission.bluetooth,
  };

  /// Whether this permission exists on the current platform at all.
  ///
  /// Anything false here is hidden from the settings list rather than shown as
  /// a row that can never be satisfied.
  bool get isSupportedHere =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

/// What the OS currently reports for one permission.
///
/// Only this status is ever stored — never the camera, photo or location
/// content the permission unlocks.
enum AppPermissionState {
  granted,
  limited,

  /// Not granted yet, but the app may still show the system prompt. This is
  /// the normal starting state and is not a problem to report.
  denied,

  /// The system will no longer prompt: only Device Settings can change it.
  permanentlyDenied,

  /// Blocked by a device policy or parental controls.
  restricted,

  /// The platform did not answer — the plugin is unavailable on this build or
  /// this permission does not exist here. Distinct from [denied]: nothing is
  /// wrong with the user's choices, we simply could not read them.
  unknown,
}

extension AppPermissionStateX on AppPermissionState {
  bool get isUsable =>
      this == AppPermissionState.granted || this == AppPermissionState.limited;

  /// True when the app can no longer show its own prompt and the shopkeeper
  /// has to go to Device Settings.
  bool get needsDeviceSettings =>
      this == AppPermissionState.permanentlyDenied ||
      this == AppPermissionState.restricted;

  /// True while the app can still put the system prompt up itself, so tapping
  /// the row is worth doing.
  bool get canStillAsk =>
      this == AppPermissionState.denied || this == AppPermissionState.unknown;

  static AppPermissionState fromStatus(PermissionStatus status) {
    if (status.isGranted) return AppPermissionState.granted;
    if (status.isLimited) return AppPermissionState.limited;
    if (status.isPermanentlyDenied) return AppPermissionState.permanentlyDenied;
    if (status.isRestricted) return AppPermissionState.restricted;
    if (status.isDenied) return AppPermissionState.denied;
    return AppPermissionState.unknown;
  }
}
