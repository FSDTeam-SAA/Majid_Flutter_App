import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../widgets/code_input_field.dart';

/// Generic "enter the 6-digit code" screen.
///
/// It is deliberately shared: sign-in two-factor, the final confirmation
/// before account deletion and the customer-consent OTP all show the same
/// screen, so the wording and error handling stay identical everywhere a code
/// is asked for. It pops `true` once [onVerify] accepts a code.
class VerifyCodePage extends StatefulWidget {
  final String title;
  final String message;

  /// Returns true when the code is correct.
  final Future<bool> Function(String code) onVerify;

  /// Optional "resend"/"use another method" action shown under the boxes.
  final Future<void> Function()? onResend;
  final String resendLabel;
  final String actionLabel;

  const VerifyCodePage({
    super.key,
    required this.title,
    required this.message,
    required this.onVerify,
    this.onResend,
    this.resendLabel = 'Resend code',
    this.actionLabel = 'Verify & Continue',
  });

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  String _code = '';
  bool _isVerifying = false;
  bool _hasError = false;
  String _error = '';

  Future<void> _submit() async {
    if (_code.length != 6 || _isVerifying) return;
    setState(() {
      _isVerifying = true;
      _hasError = false;
      _error = '';
    });

    final accepted = await widget.onVerify(_code);
    if (!mounted) return;

    if (accepted) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _isVerifying = false;
      _hasError = true;
      _error = 'That code was not correct or has expired. Try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: widget.title),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                CodeInputField(
                  hasError: _hasError,
                  enabled: !_isVerifying,
                  onChanged: (value) => setState(() {
                    _code = value;
                    _hasError = false;
                    _error = '';
                  }),
                  onCompleted: (_) => _submit(),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error,
                    style: TextStyle(
                      color: AppColors.dangerColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 26),
                AppButton(
                  label: widget.actionLabel,
                  isLoading: _isVerifying,
                  onPressed: _submit,
                ),
                if (widget.onResend != null) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton.icon(
                      onPressed: _isVerifying
                          ? null
                          : () async => widget.onResend!(),
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        widget.resendLabel,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
