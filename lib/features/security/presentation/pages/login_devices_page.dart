import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/security_models.dart';
import '../controller/security_controller.dart';

/// "Let owner see from settings how many devices are connected currently and
/// let them delete if they want to delete any."
///
/// The device this app is running on is shown but not removable — ending that
/// session is what Log out is for.
class LoginDevicesPage extends StatelessWidget {
  const LoginDevicesPage({super.key});

  Future<void> _confirmRemove(
    BuildContext context,
    SecurityController security,
    LoginDevice device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Remove this device?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '${device.name} will be signed out and will have to verify again '
          'the next time it signs in.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Remove',
              style: TextStyle(
                color: AppColors.dangerColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final removed = await security.removeDevice(device.id);
    if (removed) {
      showSuccessSnackbar('${device.name} removed');
    } else {
      showErrorSnackbar('This device cannot be removed here — log out instead');
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = SecurityController.instance;

    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Login Devices'),
          Expanded(
            child: Obx(() {
              final devices = security.devices;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    devices.isEmpty
                        ? 'No devices recorded yet'
                        : '${devices.length} device${devices.length == 1 ? '' : 's'} connected',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'These devices are currently signed in to your account. '
                    'Remove any you do not recognise.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (devices.isEmpty)
                    _EmptyState()
                  else
                    ...devices.map(
                      (device) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DeviceCard(
                          device: device,
                          onRemove: device.isCurrent
                              ? null
                              : () =>
                                    _confirmRemove(context, security, device),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Icon(
            Icons.devices_other_outlined,
            size: 34,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'Nothing to show yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Devices appear here after they sign in and are approved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final LoginDevice device;
  final VoidCallback? onRemove;

  const _DeviceCard({required this.device, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: device.isCurrent
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.fieldBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.phone_iphone_rounded,
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (device.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'This device',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    device.platform,
                    device.location,
                  ].where((value) => value.isNotEmpty).join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last active ${_relative(device.lastActive)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove device',
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.dangerColor,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  static String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}
