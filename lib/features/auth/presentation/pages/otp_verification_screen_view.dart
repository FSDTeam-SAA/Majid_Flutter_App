import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../controller/auth_controller.dart';
import '../widgets/_auth_widgets.dart';
import 'create_new_password_screen_view.dart';
import 'login_screen_view.dart';

class OtpVerificationScreenView extends StatefulWidget {
  const OtpVerificationScreenView({super.key});

  @override
  State<OtpVerificationScreenView> createState() =>
      _OtpVerificationScreenViewState();
}

class _OtpVerificationScreenViewState extends State<OtpVerificationScreenView> {
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final destinationEmail = auth.emailController.text.trim();
    final otpDescription = destinationEmail.isEmpty
        ? 'Enter the verification code we just sent to your email address.'
        : 'Enter the verification code we just sent to $destinationEmail';

    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          AuthBackButton(),
          SizedBox(height: 48),
          Text(
            'OTP Verification',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            otpDescription,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              6,
              (i) => _OtpBox(
                controller: auth.otpControllers[i],
                focusNode: _focusNodes[i],
                onChanged: (v) {
                  if (v.isNotEmpty && i < 5) {
                    _focusNodes[i + 1].requestFocus();
                  }
                  if (v.isEmpty && i > 0) {
                    _focusNodes[i - 1].requestFocus();
                  }
                },
              ),
            ),
          ),
          SizedBox(height: 32),
          Obx(
            () => AppButton(
              label: 'Verify',
              isLoading: auth.isLoading.value,
              onPressed: () async {
                bool success;
                if (auth.isEmailVerification.value) {
                  success = await auth.verifyEmail();
                  if (success) {
                    showSuccessSnackbar('Email verified successfully!');
                    Get.offAll(() => LoginScreenView());
                  }
                } else {
                  success = await auth.verifyForgotOtp();
                  if (success) {
                    Get.to(() => CreateNewPasswordScreenView());
                  }
                }
                if (!success && auth.errorMessage.isNotEmpty) {
                  showErrorSnackbar(auth.errorMessage.value);
                }
              },
            ),
          ),
          SizedBox(height: 24),
          Center(
            child: Obx(
              () => GestureDetector(
                onTap: auth.isLoading.value
                    ? null
                    : () async {
                        final success = await auth.resendOtp();
                        if (success) {
                          showSuccessSnackbar('OTP resent successfully');
                        } else if (auth.errorMessage.isNotEmpty) {
                          showErrorSnackbar(auth.errorMessage.value);
                        }
                      },
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.fieldBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.fieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
