import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/totp.dart';
import '../controller/security_controller.dart';
import '../widgets/code_input_field.dart';

/// Sets up the authenticator-app option.
///
/// The client asked for the system to "generate new codes after 30 seconds",
/// which is the standard TOTP step — so the same secret works in Google
/// Authenticator, Authy or a password manager. The live code and its
/// countdown are shown here purely so the shopkeeper can confirm their app is
/// in sync before the secret is kept.
class AuthenticatorSetupPage extends StatefulWidget {
  final String accountLabel;

  const AuthenticatorSetupPage({super.key, required this.accountLabel});

  @override
  State<AuthenticatorSetupPage> createState() => _AuthenticatorSetupPageState();
}

class _AuthenticatorSetupPageState extends State<AuthenticatorSetupPage> {
  late final SecurityController _security;
  late final String _secret;
  Timer? _ticker;

  String _entered = '';
  bool _hasError = false;
  bool _isSaving = false;
  int _secondsLeft = Totp.stepSeconds;
  String _liveCode = '';

  @override
  void initState() {
    super.initState();
    _security = SecurityController.instance;
    _secret = _security.startAuthenticatorSetup();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      _secondsLeft = Totp.secondsRemaining();
      _liveCode = Totp.code(_secret);
    });
  }

  Future<void> _confirm() async {
    if (_entered.length != Totp.digits || _isSaving) return;
    setState(() {
      _isSaving = true;
      _hasError = false;
    });

    final ok = await _security.confirmAuthenticatorSetup(
      secret: _secret,
      code: _entered,
    );
    if (!mounted) return;

    if (ok) {
      showSuccessSnackbar('Authenticator app enabled');
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _isSaving = false;
      _hasError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uri = Totp.provisioningUri(
      secret: _secret,
      account: widget.accountLabel,
    );

    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Authenticator app'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              children: [
                Text(
                  'Scan this code',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Open your authenticator app and scan the QR code, or enter '
                  'the setup key by hand. A new 6-digit code is generated '
                  'every 30 seconds.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: QrImageView(
                      data: uri,
                      size: 190,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SetupKeyRow(secret: _secret),
                const SizedBox(height: 20),
                _LiveCodeCard(code: _liveCode, secondsLeft: _secondsLeft),
                const SizedBox(height: 24),
                Text(
                  'Enter the code from your app',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                CodeInputField(
                  autofocus: false,
                  hasError: _hasError,
                  enabled: !_isSaving,
                  onChanged: (value) => setState(() {
                    _entered = value;
                    _hasError = false;
                  }),
                  onCompleted: (_) => _confirm(),
                ),
                if (_hasError) ...[
                  const SizedBox(height: 10),
                  Text(
                    'That code did not match. Check your device clock and try '
                    'the next code.',
                    style: TextStyle(
                      color: AppColors.dangerColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton(
                  label: 'Turn on authenticator',
                  isLoading: _isSaving,
                  onPressed: _confirm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupKeyRow extends StatelessWidget {
  final String secret;

  const _SetupKeyRow({required this.secret});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup key',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  secret,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy setup key',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: secret));
              showSuccessSnackbar('Setup key copied');
            },
            icon: Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Shows what the app should be displaying right now, with the 30-second
/// window draining, so a mismatch is obvious before the secret is saved.
class _LiveCodeCard extends StatelessWidget {
  final String code;
  final int secondsLeft;

  const _LiveCodeCard({required this.code, required this.secondsLeft});

  @override
  Widget build(BuildContext context) {
    final spaced = code.length == 6
        ? '${code.substring(0, 3)} ${code.substring(3)}'
        : code;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your app should show',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  spaced,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: secondsLeft / Totp.stepSeconds,
                  strokeWidth: 3,
                  backgroundColor: AppColors.fieldBorder,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
                Text(
                  '$secondsLeft',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
