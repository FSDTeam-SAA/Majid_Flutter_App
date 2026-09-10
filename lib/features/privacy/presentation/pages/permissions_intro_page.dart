import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/app_permission.dart';
import '../controller/app_permissions_controller.dart';

/// First screen after a **new device** signs in.
///
/// The client's instruction is precise: "Permission when sign in show first
/// screen permissions only for new device registrations, otherwise no need to
/// ask" — Location, Camera, Photos and Bluetooth. It explains each one and
/// lets the shopkeeper allow them here, but nothing is forced: skipping is a
/// first-class option and each feature will still ask in context when it is
/// actually used.
class PermissionsIntroPage extends StatefulWidget {
  const PermissionsIntroPage({super.key});

  /// The four the client listed, in their order.
  static const requested = [
    AppPermission.location,
    AppPermission.camera,
    AppPermission.photos,
    AppPermission.bluetooth,
  ];

  @override
  State<PermissionsIntroPage> createState() => _PermissionsIntroPageState();
}

class _PermissionsIntroPageState extends State<PermissionsIntroPage> {
  late final AppPermissionsController _permissions;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _permissions = AppPermissionsController.instance;
    _permissions.refreshStatuses();
  }

  Future<void> _allowAll() async {
    if (_isWorking) return;
    setState(() => _isWorking = true);
    for (final permission in PermissionsIntroPage.requested) {
      await _permissions.request(permission);
    }
    if (!mounted) return;
    setState(() => _isWorking = false);
    Navigator.pop(context, true);
  }

  Future<void> _requestOne(AppPermission permission) async {
    await _permissions.request(permission);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Set up this device',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'imoscan asks for these once, when a new device is '
                    'registered. You can change any of them later in Profile → '
                    'Privacy & Permissions.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...PermissionsIntroPage.requested
                      .where((permission) => permission.isSupportedHere)
                      .map(
                        (permission) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PermissionCard(
                            permission: permission,
                            state: _permissions.stateOf(permission),
                            onAllow: () => _requestOne(permission),
                          ),
                        ),
                      ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'imoscan stores the status of a permission only — '
                          'never your photos, camera images or location.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                children: [
                  AppButton(
                    label: 'Allow and continue',
                    isLoading: _isWorking,
                    onPressed: _allowAll,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isWorking
                        ? null
                        : () => Navigator.pop(context, false),
                    child: Text(
                      'Not now',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final AppPermission permission;
  final AppPermissionState state;
  final VoidCallback onAllow;

  const _PermissionCard({
    required this.permission,
    required this.state,
    required this.onAllow,
  });

  IconData get _icon => switch (permission) {
    AppPermission.camera => Icons.photo_camera_outlined,
    AppPermission.photos => Icons.photo_library_outlined,
    AppPermission.location => Icons.location_on_outlined,
    AppPermission.notifications => Icons.notifications_none_rounded,
    AppPermission.bluetooth => Icons.bluetooth_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final allowed = state.isUsable;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: allowed
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.fieldBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(_icon, size: 19, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permission.label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  permission.rationale,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (allowed)
            Icon(
              Icons.check_circle_rounded,
              size: 22,
              color: AppColors.primary,
            )
          else
            TextButton(
              onPressed: onAllow,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 44),
              ),
              child: Text(
                'Allow',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
