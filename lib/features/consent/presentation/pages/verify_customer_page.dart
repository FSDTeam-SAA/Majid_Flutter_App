import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../security/presentation/widgets/code_input_field.dart';
import '../controller/consent_controller.dart';

/// Step 2: "Verify Your Identity" — the customer enters the 6-digit code that
/// arrived with the secure link. Pops `true` once the code is accepted.
class VerifyCustomerPage extends StatefulWidget {
  const VerifyCustomerPage({super.key});

  @override
  State<VerifyCustomerPage> createState() => _VerifyCustomerPageState();
}

class _VerifyCustomerPageState extends State<VerifyCustomerPage> {
  final ConsentController _consent = ConsentController.instance;

  String _code = '';
  bool _isVerifying = false;
  bool _hasError = false;

  Future<void> _verify() async {
    if (_code.length != 6 || _isVerifying) return;
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    final ok = await _consent.verifyCode(_code);
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

  Future<void> _resend() async {
    final dispatch = await _consent.sendLinkAndCode();
    if (!mounted) return;
    if (dispatch.debugCode != null && !kReleaseMode) {
      showSuccessSnackbar('Test code: ${dispatch.debugCode}');
    } else {
      showSuccessSnackbar('Code re-sent');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Obx(() {
        final destination =
            _consent.active.value?.maskedDestination ?? 'the customer';

        return SingleChildScrollView(
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
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_person_outlined,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Verify Your Identity',
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
                  'Enter the 6-digit code sent to $destination',
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
                  'That code was not correct or has expired. Send a new one.',
                  style: TextStyle(
                    color: AppColors.dangerColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 26),
              AppButton(
                label: 'Verify & Continue',
                isLoading: _isVerifying,
                onPressed: _verify,
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  onPressed: _isVerifying ? null : _resend,
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
