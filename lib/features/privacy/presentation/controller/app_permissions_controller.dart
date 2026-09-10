import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/app_permission.dart';

/// Reads and requests OS permissions, and nothing else.
///
/// ## iOS builds started from Xcode.app
///
/// `permission_handler_apple` decides which permissions to compile in by
/// reading the app's `Info.plist` from its SwiftPM manifest. The manifest runs
/// sandboxed with no Xcode build settings, so it locates the app by walking up
/// from the working directory. That works for `flutter run` and
/// `flutter build ios`, but a build started from Xcode.app runs with `/` as its
/// working directory — nothing is found, **every permission is compiled out**,
/// and each status reads as unavailable.
///
/// If that happens, either run through `flutter run`, or point the manifest at
/// the plist once:
///
/// ```sh
/// launchctl setenv PERMISSION_HANDLER_INFO_PLIST \
///     "$(pwd)/ios/Runner/Info.plist"
/// rm -rf ~/Library/Developer/Xcode/DerivedData
/// ```
///
/// [isPlatformUnavailable] detects the compiled-out case so the settings
/// screen can say so rather than showing five rows the shopkeeper cannot fix.
///
/// Two rules from the client's developer notes are enforced here:
///
/// * **Request in context.** [ensure] is called by the feature that needs the
///   permission at the moment it needs it. Nothing is requested at launch.
/// * **Live OS status.** [refresh] always re-reads the real platform state, so
///   a permission revoked in Device Settings shows as revoked here. The app
///   stores the status only — never the content it unlocks.
class AppPermissionsController extends GetxController with WidgetsBindingObserver {
  final statuses = <AppPermission, AppPermissionState>{}.obs;
  final isRefreshing = false.obs;

  static AppPermissionsController get instance {
    if (!Get.isRegistered<AppPermissionsController>()) {
      Get.put(AppPermissionsController(), permanent: true);
    }
    return Get.find<AppPermissionsController>();
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refreshStatuses();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Coming back from Device Settings is the usual way a status changes
  /// behind the app's back, so re-read on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refreshStatuses();
  }

  AppPermissionState stateOf(AppPermission permission) =>
      statuses[permission] ?? AppPermissionState.unknown;

  /// True when the platform side never answered.
  ///
  /// It means the native plugin is missing from this build — most often an
  /// iOS build started from Xcode.app, where permission_handler compiles every
  /// permission out because it cannot locate the app's Info.plist. Surfaced so
  /// the settings screen can say that plainly instead of blaming the user's
  /// choices.
  final isPlatformUnavailable = false.obs;

  Future<void> refreshStatuses() async {
    isRefreshing.value = true;
    try {
      var unreadable = 0;
      for (final permission in AppPermission.values) {
        final state = await _read(permission);
        statuses[permission] = state;
        if (state == AppPermissionState.unknown) unreadable++;
      }
      // One unknown is a quirk of a single permission; all of them means the
      // plugin itself is not answering.
      isPlatformUnavailable.value = unreadable == AppPermission.values.length;
      statuses.refresh();
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<AppPermissionState> _read(AppPermission permission) async {
    if (!permission.isSupportedHere) return AppPermissionState.unknown;

    try {
      final status = await permission.handle.status;
      return AppPermissionStateX.fromStatus(status);
    } on MissingPluginException catch (e) {
      debugPrint(
        'permission_handler is not registered in this build '
        '(${permission.name}): $e',
      );
      return AppPermissionState.unknown;
    } catch (e) {
      // Desktop and some emulators have no implementation for every
      // permission; an unknown status is better than crashing the settings
      // screen.
      debugPrint('Permission status error for ${permission.name}: $e');
      return AppPermissionState.unknown;
    }
  }

  /// Requests [permission] and returns the resulting state.
  Future<AppPermissionState> request(AppPermission permission) async {
    if (!permission.isSupportedHere) return AppPermissionState.unknown;

    try {
      final status = await permission.handle.request();
      final state = AppPermissionStateX.fromStatus(status);
      statuses[permission] = state;
      statuses.refresh();
      if (state != AppPermissionState.unknown) {
        isPlatformUnavailable.value = false;
      }
      return state;
    } catch (e) {
      debugPrint('Permission request error for ${permission.name}: $e');
      return AppPermissionState.unknown;
    }
  }

  /// The in-context entry point: returns true when the feature may proceed.
  ///
  /// Callers should use this immediately before the action that needs the
  /// access — opening the scanner, starting delivery tracking — rather than
  /// at app start.
  Future<bool> ensure(AppPermission permission) async {
    final current = await _read(permission);
    statuses[permission] = current;
    statuses.refresh();

    if (current.isUsable) return true;
    if (current.needsDeviceSettings) return false;

    final result = await request(permission);
    if (result.isUsable) return true;

    // The platform could not answer, so we cannot prove the feature is
    // blocked. Letting it run is better than refusing on a status we never
    // actually read — the OS still enforces the real permission underneath.
    return result == AppPermissionState.unknown;
  }

  Future<void> openSettings() => openAppSettings();
}
