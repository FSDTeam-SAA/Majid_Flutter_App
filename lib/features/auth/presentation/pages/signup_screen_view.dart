import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controller/auth_controller.dart';
import '../widgets/_auth_widgets.dart';
import 'otp_verification_screen_view.dart';

class SignupScreenView extends StatelessWidget {
  const SignupScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const AuthBackButton(),
          const SizedBox(height: 36),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Create Your ',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'Imo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'scan',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: '\nAccount',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            hint: 'First Name',
            controller: auth.firstNameController,
          ),
          const SizedBox(height: 14),
          AppTextField(
            hint: 'Last Name',
            controller: auth.lastNameController,
          ),
          const SizedBox(height: 14),
          AppTextField(
            hint: 'Enter your email',
            controller: auth.emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          AppTextField(
            hint: 'Password',
            controller: auth.passwordController,
            isPassword: true,
          ),
          const SizedBox(height: 14),
          AppTextField(
            hint: 'Confirm Password',
            controller: auth.confirmPasswordController,
            isPassword: true,
          ),
          const SizedBox(height: 28),
          Obx(
            () => AppButton(
              label: 'Create Account',
              isLoading: auth.isLoading.value,
              onPressed: () async {
                if (auth.passwordController.text !=
                    auth.confirmPasswordController.text) {
                  showErrorSnackbar('Passwords do not match');
                  return;
                }
                final success = await auth.register();
                if (success) {
                  showSuccessSnackbar(
                    'Account created! Please verify your email.',
                  );
                  Get.to(() => const OtpVerificationScreenView());
                } else if (auth.errorMessage.isNotEmpty) {
                  showErrorSnackbar(auth.errorMessage.value);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: AuthLink(
              text: 'Already have an account? ',
              linkText: 'Log in now',
              onTap: () => Get.back(),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
