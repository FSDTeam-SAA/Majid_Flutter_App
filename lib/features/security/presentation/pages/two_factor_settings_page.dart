import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../domain/security_models.dart';
import '../controller/security_controller.dart';
import 'authenticator_setup_page.dart';
import 'verify_code_page.dart';

/// Two-factor authentication settings for the account owner.
///
/// The three delivery routes the client listed all live here: a code from an
/// authenticator app, a code by email, and a code by text message. The account
/// email and phone are confirmed from this screen too, because a code can only
/// be sent to a destination that has been verified.
class TwoFactorSettingsPage extends StatelessWidget {
  const TwoFactorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final security = SecurityController.instance;
    final profile = Get.find<ProfileController>();

    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Two-Factor Authentication'),
          Expanded(
            child: Obx(() {
              final settings = security.settings.value;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  _IntroCard(enabled: settings.enabled),
                  const SizedBox(height: 18),
                  _ToggleRow(
                    value: settings.enabled,
                    onChanged: (value) async {
                      if (value && !settings.isConfirmed) {
                        showErrorSnackbar(
                          'Confirm your email or phone number first',
                        );
                        return;
                      }
                      await security.setEnabled(value);
                    },
                  ),
                  const SizedBox(height: 22),
                  _SectionLabel('Verification method'),
                  const SizedBox(height: 10),
                  ...TwoFactorMethod.values.map(
                    (method) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MethodRow(
                        method: method,
                        selected: settings.method == method,
                        isConfigured: _isConfigured(method, settings),
                        onTap: () => _selectMethod(
                          context,
                          security,
                          profile,
                          method,
                          settings,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _SectionLabel('Verified email & phone'),
                  const SizedBox(height: 10),
                  _DestinationRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: profile.email.isEmpty
                        ? 'Not set on your account'
                        : profile.email,
                    verified: settings.emailVerified,
                    onVerify: profile.email.isEmpty
                        ? null
                        : () => _verifyDestination(
                            context,
                            security,
                            TwoFactorMethod.email,
                            profile.email,
                          ),
                  ),
                  const SizedBox(height: 10),
                  _DestinationRow(
                    icon: Icons.smartphone_rounded,
                    label: 'Phone number',
                    value: profile.phone.isEmpty
                        ? 'Not set on your account'
                        : profile.phone,
                    verified: settings.phoneVerified,
                    onVerify: profile.phone.isEmpty
                        ? null
                        : () => _verifyDestination(
                            context,
                            security,
                            TwoFactorMethod.sms,
                            profile.phone,
                          ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Two-factor authentication is required for owners and '
                    'administrators. Staff accounts inherit the shop policy.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.5,
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

  bool _isConfigured(TwoFactorMethod method, TwoFactorSettings settings) =>
      switch (method) {
        TwoFactorMethod.authenticator =>
          (settings.authenticatorSecret ?? '').isNotEmpty,
        TwoFactorMethod.email => settings.emailVerified,
        TwoFactorMethod.sms => settings.phoneVerified,
      };

  Future<void> _selectMethod(
    BuildContext context,
    SecurityController security,
    ProfileController profile,
    TwoFactorMethod method,
    TwoFactorSettings settings,
  ) async {
    if (method == TwoFactorMethod.authenticator) {
      if ((settings.authenticatorSecret ?? '').isEmpty) {
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AuthenticatorSetupPage(
              accountLabel: profile.email.isEmpty
                  ? 'imoscan owner'
                  : profile.email,
            ),
          ),
        );
        return;
      }
      await security.setMethod(method);
      return;
    }

    final destination = method == TwoFactorMethod.email
        ? profile.email
        : profile.phone;

    if (destination.isEmpty) {
      showErrorSnackbar(
        'Add ${method == TwoFactorMethod.email ? 'an email address' : 'a phone number'} '
        'to your account first',
      );
      return;
    }

    if (!_isConfigured(method, settings)) {
      final verified = await _verifyDestination(
        context,
        security,
        method,
        destination,
      );
      if (!verified) return;
    }

    await security.setMethod(method);
  }

  /// Sends a code to [destination] and marks it confirmed once entered.
  Future<bool> _verifyDestination(
    BuildContext context,
    SecurityController security,
    TwoFactorMethod method,
    String destination,
  ) async {
    final dispatch = await security.sendChallenge(
      method: method,
      destination: destination,
    );
    if (!context.mounted) return false;

    if (dispatch.debugCode != null && !kReleaseMode) {
      // No mail/SMS gateway in the app: surfaced in debug only so the flow can
      // be walked on device before the backend routes exist.
      showSuccessSnackbar('Test code: ${dispatch.debugCode}');
    }

    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyCodePage(
          title: 'Security Verification',
          message: 'Enter the 6-digit code sent to $destination.',
          onVerify: security.verifyChallenge,
          onResend: () async {
            await security.sendChallenge(
              method: method,
              destination: destination,
            );
          },
        ),
      ),
    );

    if (verified != true) return false;

    if (method == TwoFactorMethod.email) {
      await security.setEmailVerified(true);
    } else {
      await security.setPhoneVerified(true);
    }
    return true;
  }
}

class _IntroCard extends StatelessWidget {
  final bool enabled;

  const _IntroCard({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled
                      ? 'Two-factor is on'
                      : 'Add a second step to sign in',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Every time a new device signs in, we ask for a verification '
                  'code and let you approve or deny the device.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
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

class _ToggleRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Require a code at sign-in',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final TwoFactorMethod method;
  final bool selected;
  final bool isConfigured;
  final VoidCallback onTap;

  const _MethodRow({
    required this.method,
    required this.selected,
    required this.isConfigured,
    required this.onTap,
  });

  IconData get _icon => switch (method) {
    TwoFactorMethod.authenticator => Icons.key_outlined,
    TwoFactorMethod.email => Icons.mail_outline_rounded,
    TwoFactorMethod.sms => Icons.sms_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.fieldBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icon,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConfigured
                          ? method.description
                          : 'Tap to set up — ${method.description.toLowerCase()}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.fieldBorder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool verified;
  final VoidCallback? onVerify;

  const _DestinationRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.verified,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (verified)
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Confirmed',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else if (onVerify != null)
            TextButton(
              onPressed: onVerify,
              child: Text(
                'Confirm',
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
