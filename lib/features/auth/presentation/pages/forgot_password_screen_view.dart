import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controller/auth_controller.dart';
import '../widgets/_auth_widgets.dart';
import 'otp_verification_screen_view.dart';

class ForgotPasswordScreenView extends StatelessWidget {
  const ForgotPasswordScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const AuthBackButton(),
                const SizedBox(height: 48),
                const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Don't worry! It occurs. Please enter the email address linked with your account.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 36),
                AppTextField(
                  hint: 'Email',
                  controller: auth.emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 28),
                Obx(
                  () => AppButton(
                    label: 'Send Code',
                    isLoading: auth.isLoading.value,
                    onPressed: () async {
                      final success = await auth.forgotPassword();
                      if (success) {
                        showSuccessSnackbar('OTP sent to your email');
                        Get.to(() => const OtpVerificationScreenView());
                      } else if (auth.errorMessage.isNotEmpty) {
                        showErrorSnackbar(auth.errorMessage.value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: AuthLink(
                    text: 'Already have an account? ',
                    linkText: 'Log in now',
                    onTap: () => Get.until((route) => route.isFirst),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
