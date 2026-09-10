import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/controller/auth_controller.dart';
import '../../../auth/presentation/pages/login_screen_view.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../security/domain/security_models.dart';
import '../../../security/presentation/controller/security_controller.dart';
import '../../../security/presentation/pages/verify_code_page.dart';
import '../../data/data_export_service.dart';

/// Permanent account deletion.
///
/// The client's sequence is followed exactly: show the delete action clearly,
/// offer to download the inventory and everything else saved with imoscan
/// first, and only then ask for a verification code one last time.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final DataExportService _exports = DataExportService();

  bool _acknowledged = false;
  bool _isExporting = false;
  bool _isDeleting = false;
  bool _hasExported = false;

  /// Step 1 of the final message: take your data with you.
  Future<void> _downloadFirst() async {
    setState(() => _isExporting = true);
    try {
      final personal = await _exports.exportPersonalData();
      final business = await _exports.exportBusinessData();
      if (!mounted) return;

      setState(() => _hasExported = true);
      showSuccessSnackbar('Saved to ${personal.locationLabel}');
      await Share.shareXFiles(
        [XFile(personal.file.path), XFile(business.file.path)],
        text: 'imoscan data export',
      );
    } catch (e) {
      if (mounted) showErrorSnackbar('Could not build the export: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Step 2: the last verification code before anything is destroyed.
  Future<bool> _verifyBeforeDelete() async {
    final security = SecurityController.instance;
    await security.load();
    final settings = security.settings.value;
    final profile = Get.find<ProfileController>();

    var message = 'Enter the code from your authenticator app.';

    if (settings.method != TwoFactorMethod.authenticator) {
      final destination = settings.method == TwoFactorMethod.email
          ? profile.email
          : profile.phone;
      if (destination.isEmpty) {
        showErrorSnackbar(
          'Add and confirm an email or phone number before deleting',
        );
        return false;
      }
      await security.sendChallenge(
        method: settings.method,
        destination: destination,
      );
      message = 'Enter the 6-digit code sent to $destination.';
    }

    if (!mounted) return false;
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyCodePage(
          title: 'Final verification',
          message: message,
          onVerify: security.verifyChallenge,
          actionLabel: 'Verify & Delete',
        ),
      ),
    );
    return verified == true;
  }

  Future<void> _delete() async {
    if (!_acknowledged || _isDeleting) return;

    final confirmed = await _confirmDialog();
    if (confirmed != true) return;

    final verified = await _verifyBeforeDelete();
    if (!verified || !mounted) return;

    setState(() => _isDeleting = true);
    final profile = Get.find<ProfileController>();

    try {
      if (profile.userId.isEmpty) await profile.fetchProfile();
      if (profile.userId.isEmpty) {
        throw const FormatException('Your account id could not be resolved');
      }

      await ApiClient(baseUrl).delete(UserEndpoints.deleteUser(profile.userId));

      // Local security records go with the account: devices, the
      // authenticator secret and any live challenge.
      await SecurityController.instance.wipe();
      await Get.find<AuthController>().logout();

      if (!mounted) return;
      showSuccessSnackbar('Your account has been deleted');
      Get.offAll(() => const LoginScreenView());
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showErrorSnackbar(
        e.response?.data?['message']?.toString() ??
            'Could not delete the account. Please contact support.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showErrorSnackbar('Could not delete the account: $e');
    }
  }

  Future<bool?> _confirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.dangerColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.dangerColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Delete Account?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'Your account and associated personal data will be permanently '
          'deleted, except records retained for legal obligations.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Delete Account'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.dangerColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.dangerColor,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Delete your imoscan account',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This cannot be undone. Your account and associated personal '
                  'data will be permanently deleted, except records we must '
                  'keep for legal obligations such as accounting and fraud '
                  'prevention.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                _DownloadFirstCard(
                  isBusy: _isExporting,
                  hasExported: _hasExported,
                  onDownload: _downloadFirst,
                ),
                const SizedBox(height: 18),
                _WhatHappensCard(),
                const SizedBox(height: 18),
                _AcknowledgeRow(
                  value: _acknowledged,
                  onChanged: (value) =>
                      setState(() => _acknowledged = value ?? false),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _acknowledged && !_isDeleting ? _delete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dangerColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.dangerColor.withValues(
                        alpha: 0.35,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'You can also delete your account from the imoscan website.',
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
        ],
      ),
    );
  }
}

class _DownloadFirstCard extends StatelessWidget {
  final bool isBusy;
  final bool hasExported;
  final VoidCallback onDownload;

  const _DownloadFirstCard({
    required this.isBusy,
    required this.hasExported,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_download_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Download your data first',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasExported)
                Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Take your inventory, invoices, customers and account record with '
            'you. Once the account is deleted this is no longer available.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isBusy ? null : onDownload,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : Text(
                      hasExported ? 'Download again' : 'Download my data',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatHappensCard extends StatelessWidget {
  static const _deleted = [
    'Your profile, login details and two-factor setup',
    'Your connected devices and sessions',
    'Shop settings, logo and preferences',
  ];

  static const _retained = [
    'Invoice and accounting records, normally up to six years',
    'Security and fraud-prevention logs, for a limited period',
    'Anything else the law requires us to keep',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _list(
            title: 'Deleted permanently',
            icon: Icons.delete_outline_rounded,
            color: AppColors.dangerColor,
            items: _deleted,
          ),
          const SizedBox(height: 16),
          _list(
            title: 'Kept for legal obligations',
            icon: Icons.gavel_rounded,
            color: AppColors.textSecondary,
            items: _retained,
          ),
        ],
      ),
    );
  }

  Widget _list({
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 25, bottom: 5),
            child: Text(
              '• $item',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
      ],
    );
  }
}

class _AcknowledgeRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _AcknowledgeRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.dangerColor,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'I understand this is permanent and I have downloaded anything '
                'I need to keep.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
