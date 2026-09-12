import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/security_models.dart';
import '../controller/security_controller.dart';
import '../widgets/code_input_field.dart';

/// The "Security Verification" step of signing in.
///
/// The client's three routes are all reachable from here: the authenticator
/// app's rolling code, a code emailed to the registered address, and a code
/// texted to the registered number. "Use another method" switches between
/// them without leaving the screen. It pops `true` on success.
class TwoFactorChallengePage extends StatefulWidget {
  final TwoFactorSettings settings;
  final String email;
  final String phone;

  const TwoFactorChallengePage({
    super.key,
    required this.settings,
    required this.email,
    required this.phone,
  });

  @override
  State<TwoFactorChallengePage> createState() => _TwoFactorChallengePageState();
}

class _TwoFactorChallengePageState extends State<TwoFactorChallengePage> {
  late final SecurityController _security;
  late TwoFactorMethod _method;

  String _code = '';
  bool _isVerifying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _security = SecurityController.instance;
    _method = widget.settings.method;
    if (_method != TwoFactorMethod.authenticator) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _dispatch());
    }
  }

  String get _destination => switch (_method) {
    TwoFactorMethod.authenticator => 'your authenticator app',
    TwoFactorMethod.email => widget.email,
    TwoFactorMethod.sms => widget.phone,
  };

  String get _message => _method == TwoFactorMethod.authenticator
      ? 'Enter the 6-digit code from your authenticator app.'
      : 'Enter the 6-digit code sent to $_destination.';

  Future<void> _dispatch() async {
    if (_method == TwoFactorMethod.authenticator) return;
    await _security.sendChallenge(
      method: _method,
      destination: _destination,
    );
    if (!mounted) return;
  }

  /// The methods that are actually set up on this account — offering an
  /// unconfigured route would just dead-end the sign-in.
  List<TwoFactorMethod> get _available => [
    if ((widget.settings.authenticatorSecret ?? '').isNotEmpty)
      TwoFactorMethod.authenticator,
    if (widget.settings.emailVerified && widget.email.isNotEmpty)
      TwoFactorMethod.email,
    if (widget.settings.phoneVerified && widget.phone.isNotEmpty)
      TwoFactorMethod.sms,
  ];

  Future<void> _switchMethod() async {
    final options = _available.where((method) => method != _method).toList();
    if (options.isEmpty) {
      showErrorSnackbar('No other verification method is set up');
      return;
    }

    final picked = await showModalBottomSheet<TwoFactorMethod>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 16),
            for (final option in options)
              ListTile(
                leading: Icon(
                  switch (option) {
                    TwoFactorMethod.authenticator => Icons.key_outlined,
                    TwoFactorMethod.email => Icons.mail_outline_rounded,
                    TwoFactorMethod.sms => Icons.sms_outlined,
                  },
                  color: AppColors.primary,
                ),
                title: Text(
                  option.label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  option.description,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _method = picked;
      _code = '';
      _hasError = false;
    });
    await _security.setMethod(picked);
    await _dispatch();
  }

  Future<void> _verify() async {
    if (_code.length != 6 || _isVerifying) return;
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    final ok = await _security.verifyChallenge(_code, email: widget.email);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isVerifying = false;
      _hasError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () => Navigator.pop(context, false),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'Security Verification',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            CodeInputField(
              hasError: _hasError,
              enabled: !_isVerifying,
              onChanged: (value) => setState(() {
                _code = value;
                _hasError = false;
              }),
              onCompleted: (_) => _verify(),
            ),
            if (_hasError) ...[
              const SizedBox(height: 12),
              Text(
                'That code was not correct or has expired.',
                style: TextStyle(
                  color: AppColors.dangerColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 26),
            AppButton(
              label: 'Verify & Sign In',
              isLoading: _isVerifying,
              onPressed: _verify,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _isVerifying ? null : _switchMethod,
                icon: Icon(
                  Icons.autorenew_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Use another method',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (_method != TwoFactorMethod.authenticator)
              Center(
                child: TextButton(
                  onPressed: _isVerifying ? null : _dispatch,
                  child: Text(
                    'Resend code',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
