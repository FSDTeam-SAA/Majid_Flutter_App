import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../app_ground_view.dart';
import '../controller/auth_controller.dart';
import '../widgets/_auth_widgets.dart';
import 'signup_screen_view.dart';
import 'forgot_password_screen_view.dart';

class LoginScreenView extends StatelessWidget {
  const LoginScreenView({super.key});

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
                const SizedBox(height: 64),
                const Text(
                  'Welcome Back to',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const ImoscanTitle(),
                const SizedBox(height: 40),
                AppTextField(
                  hint: 'Enter your email',
                  controller: auth.emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  hint: 'Enter your password',
                  controller: auth.passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 24),
                Obx(
                  () => AppButton(
                    label: 'Sign In',
                    isLoading: auth.isLoading.value,
                    onPressed: () async {
                      final success = await auth.login();
                      if (success) {
                        Get.offAll(() => const AppGroundView());
                      } else if (auth.errorMessage.isNotEmpty) {
                        showErrorSnackbar(auth.errorMessage.value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Get.to(() => const ForgotPasswordScreenView()),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: AuthLink(
                    text: "Don't have an account? ",
                    linkText: 'Register Now',
                    onTap: () => Get.to(() => const SignupScreenView()),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
