import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../legal/domain/legal_documents.dart';
import '../../../legal/presentation/pages/legal_document_page.dart';
import '../../../profile/presentation/widgets/profile_menu_item.dart';
import '../../../security/presentation/controller/security_controller.dart';
import '../../../security/presentation/pages/login_devices_page.dart';
import '../../../security/presentation/pages/two_factor_settings_page.dart';
import '../../domain/app_permission.dart';
import '../controller/app_permissions_controller.dart';
import 'delete_account_page.dart';
import 'download_my_data_page.dart';

/// Profile → Privacy & Permissions.
///
/// Two rules from the client's developer notes shape this screen:
///
/// * it shows the **live OS status** for each permission rather than a value
///   the app remembers, and explains what to do when access is denied; and
/// * it stores **permission status only** — never camera, photo or location
///   content just because a permission happens to be granted.
///
/// The microphone row is absent by design: that feature was removed and the
/// declaration taken out of both platform manifests.
class PrivacyPermissionsPage extends StatefulWidget {
  const PrivacyPermissionsPage({super.key});

  @override
  State<PrivacyPermissionsPage> createState() => _PrivacyPermissionsPageState();
}

class _PrivacyPermissionsPageState extends State<PrivacyPermissionsPage> {
  late final AppPermissionsController _permissions;
  late final SecurityController _security;

  @override
  void initState() {
    super.initState();
    _permissions = AppPermissionsController.instance;
    _security = SecurityController.instance;
    _permissions.refreshStatuses();
    _security.load();
  }

  /// Tapping a permission row asks for it in context. If the OS will no
  /// longer prompt, we explain why and offer Device Settings instead.
  Future<void> _handlePermissionTap(AppPermission permission) async {
    final state = _permissions.stateOf(permission);

    // Already settled either way: explain it rather than firing a prompt the
    // OS would ignore.
    if (state.needsDeviceSettings || state.isUsable) {
      await _showDetailSheet(permission, state);
      return;
    }

    final granted = await _permissions.request(permission);
    if (!mounted) return;
    if (!granted.isUsable) {
      await _showDetailSheet(permission, _permissions.stateOf(permission));
    }
  }

  Future<void> _showDetailSheet(
    AppPermission permission,
    AppPermissionState state,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBorder,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                permission.label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                permission.rationale,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      state.isUsable
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 18,
                      color: state.isUsable
                          ? AppColors.primary
                          : state.needsDeviceSettings
                          ? AppColors.dangerColor
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _explain(permission, state),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (state.canStillAsk)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _permissions.request(permission);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.buttonText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Allow now',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (state.canStillAsk) const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _permissions.openSettings();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Open Device Settings',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _explain(AppPermission permission, AppPermissionState state) {
    return switch (state) {
      AppPermissionState.granted =>
        'Allowed. imoscan uses it only for ${permission.purpose.toLowerCase()}.',
      AppPermissionState.limited =>
        'Limited access. Only the items you select are shared with imoscan.',
      AppPermissionState.denied =>
        'Not granted yet. imoscan will ask the first time you use '
            '${permission.purpose.toLowerCase()}.',
      AppPermissionState.permanentlyDenied =>
        'Blocked on this device. Turn it back on in Device Settings to use '
            '${permission.purpose.toLowerCase()}.',
      AppPermissionState.restricted =>
        'Restricted by a device policy, so imoscan cannot request it.',
      // Not the shopkeeper's doing: the platform never answered, so pointing
      // them at Device Settings would send them somewhere that shows nothing
      // wrong.
      AppPermissionState.unknown =>
        'This build cannot read the system permission state. imoscan will '
            'still ask for access the first time you use '
            '${permission.purpose.toLowerCase()}.',
    };
  }

  /// The value column of each row: the live OS state, in the wording the
  /// client's screen uses.
  ///
  /// "Ask When Needed" / "System Picker" / "While Using" describe how imoscan
  /// uses the access, and are the right words both when it is granted and when
  /// it has simply not been asked for yet — the app requests in context, so
  /// nothing is broken in that state. Only a genuine block reads as a problem.
  String _statusLabel(AppPermission permission, AppPermissionState state) {
    return switch (state) {
      AppPermissionState.granted => permission.grantedLabel,
      AppPermissionState.limited => 'Limited',
      AppPermissionState.denied ||
      AppPermissionState.unknown => permission.pendingLabel,
      AppPermissionState.permanentlyDenied => 'Blocked',
      AppPermissionState.restricted => 'Restricted',
    };
  }

  /// Green while everything is fine, red once the OS has to be involved.
  Color _statusColor(AppPermissionState state) {
    if (state.needsDeviceSettings) return AppColors.dangerColor;
    if (state.isUsable) return AppColors.primary;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Privacy & Permissions'),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _permissions.refreshStatuses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                children: [
                  _IntroCard(),
                  Obx(() {
                    if (!_permissions.isPlatformUnavailable.value) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: _PlatformUnavailableCard(),
                    );
                  }),
                  const SizedBox(height: 22),
                  _SectionLabel('App permissions'),
                  const SizedBox(height: 10),
                  Obx(() {
                    // Touch the map so the rows rebuild when a status changes.
                    _permissions.statuses.length;
                    return Column(
                      children: [
                        for (final permission in AppPermission.values)
                          if (permission.isSupportedHere)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ProfileMenuItem(
                                leadingIcon: _iconFor(permission),
                                label: permission.label,
                                value: _statusLabel(
                                  permission,
                                  _permissions.stateOf(permission),
                                ),
                                valueColor: _statusColor(
                                  _permissions.stateOf(permission),
                                ),
                                backgroundColor: AppColors.cardBackground,
                                borderColor: AppColors.fieldBorder,
                                onTap: () => _handlePermissionTap(permission),
                              ),
                            ),
                      ],
                    );
                  }),
                  const SizedBox(height: 6),
                  ProfileMenuItem(
                    leadingIcon: Icons.settings_outlined,
                    label: 'Open Device Settings',
                    backgroundColor: AppColors.cardBackground,
                    borderColor: AppColors.fieldBorder,
                    onTap: _permissions.openSettings,
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('Security'),
                  const SizedBox(height: 10),
                  Obx(() {
                    final settings = _security.settings.value;
                    final deviceCount = _security.devices.length;

                    return Column(
                      children: [
                        ProfileMenuItem(
                          leadingIcon: Icons.lock_outline_rounded,
                          label: 'Two-Factor Authentication',
                          value: settings.enabled ? 'Enabled' : 'Off',
                          backgroundColor: AppColors.cardBackground,
                          borderColor: AppColors.fieldBorder,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TwoFactorSettingsPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ProfileMenuItem(
                          leadingIcon: Icons.verified_outlined,
                          label: 'Verified Email & Phone',
                          value: settings.isConfirmed
                              ? 'Confirmed'
                              : 'Not confirmed',
                          backgroundColor: AppColors.cardBackground,
                          borderColor: AppColors.fieldBorder,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TwoFactorSettingsPage(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ProfileMenuItem(
                          leadingIcon: Icons.devices_outlined,
                          label: 'Login Devices',
                          value: deviceCount == 0
                              ? 'None recorded'
                              : '$deviceCount Device${deviceCount == 1 ? '' : 's'}',
                          backgroundColor: AppColors.cardBackground,
                          borderColor: AppColors.fieldBorder,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginDevicesPage(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  _SectionLabel('Privacy & account'),
                  const SizedBox(height: 10),
                  ProfileMenuItem(
                    leadingIcon: Icons.cloud_download_outlined,
                    label: 'Download My Data',
                    backgroundColor: AppColors.cardBackground,
                    borderColor: AppColors.fieldBorder,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DownloadMyDataPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    leadingIcon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    backgroundColor: AppColors.cardBackground,
                    borderColor: AppColors.fieldBorder,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalDocumentPage(
                          document: LegalDocuments.privacyPolicy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ProfileMenuItem(
                    leadingIcon: Icons.delete_outline_rounded,
                    label: 'Delete Account',
                    accentColor: AppColors.dangerColor,
                    backgroundColor: AppColors.cardBackground,
                    borderColor: AppColors.dangerColor.withValues(alpha: 0.35),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeleteAccountPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'You can change device permissions at any time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(AppPermission permission) => switch (permission) {
    AppPermission.camera => Icons.photo_camera_outlined,
    AppPermission.photos => Icons.photo_library_outlined,
    AppPermission.location => Icons.location_on_outlined,
    AppPermission.notifications => Icons.notifications_none_rounded,
    AppPermission.bluetooth => Icons.bluetooth_outlined,
  };
}

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Control what imoscan can access. Permissions are requested only '
              'when a feature needs them.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Shown when the platform answered for nothing at all.
///
/// This is a build problem rather than a user choice, so it is called out
/// separately instead of leaving five rows reading "Unavailable" as though the
/// shopkeeper had denied everything.
class _PlatformUnavailableCard extends StatelessWidget {
  const _PlatformUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.dangerColor.withValues(alpha: 0.26),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.dangerColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This build cannot read system permission states, so the values '
              'below are placeholders. Each feature will still ask for access '
              'the first time it is used.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
