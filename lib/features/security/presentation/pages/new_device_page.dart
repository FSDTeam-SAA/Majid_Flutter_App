import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/security_models.dart';
import '../controller/security_controller.dart';

/// "New Device Detected" — the owner's approve/deny step.
///
/// The client asked for the owner to be able to confirm a sign-in three ways:
/// a pop-up notification on their registered device, an email, or their
/// number. This screen is what all three routes land on, so the decision and
/// its wording are identical however the owner got here. It pops `true` when
/// the device is approved.
class NewDevicePage extends StatefulWidget {
  final NewDeviceRequest request;

  const NewDevicePage({super.key, required this.request});

  @override
  State<NewDevicePage> createState() => _NewDevicePageState();
}

class _NewDevicePageState extends State<NewDevicePage> {
  bool _isBusy = false;

  Future<void> _decide(bool approve) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);

    final security = SecurityController.instance;
    if (approve) {
      await security.approvePendingRequest();
    } else {
      await security.denyPendingRequest();
    }

    if (!mounted) return;
    Navigator.pop(context, approve);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return GradientScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phonelink_lock_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'New Device Detected',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Someone is trying to sign in to your imoscan account from a '
              'device we have not seen before. Approve it only if this is you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.tablet_mac_rounded,
                    label: request.deviceName,
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: request.location,
                  ),
                  _Divider(),
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: _formatWhen(request.requestedAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Approve Device',
              isLoading: _isBusy,
              onPressed: () => _decide(true),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isBusy ? null : () => _decide(false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.fieldBorder),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Deny Access',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Denying will block this sign-in. If it was not you, change your '
              'password straight away.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatWhen(DateTime time) {
    final now = DateTime.now();
    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour < 12 ? 'AM' : 'PM';
    final day = isToday
        ? 'Today'
        : '${time.day.toString().padLeft(2, '0')}/'
              '${time.month.toString().padLeft(2, '0')}/${time.year}';
    return '$day at $hour:$minute $suffix';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Divider(height: 1, color: AppColors.fieldBorder),
    );
  }
}
