import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/animation/app_entrance.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../app_ground_view.dart';
import '../controller/auth_controller.dart';
import '../widgets/_auth_widgets.dart';
import 'signup_screen_view.dart';
import 'forgot_password_screen_view.dart';
import 'otp_verification_screen_view.dart';

class LoginScreenView extends StatelessWidget {
  const LoginScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 64),
                            Text(
                              'Welcome Back to',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ).entrance(index: 0, begin: const Offset(0, 0.04)),
                            const ImoscanTitle().entrance(
                              index: 1,
                              begin: const Offset(0, 0.04),
                            ),
                            const SizedBox(height: 40),
                            AppTextField(
                              hint: 'Enter your email',
                              controller: auth.emailController,
                              keyboardType: TextInputType.emailAddress,
                            ).entrance(index: 2),
                            const SizedBox(height: 16),
                            AppTextField(
                              hint: 'Enter your password',
                              controller: auth.passwordController,
                              isPassword: true,
                            ).entrance(index: 3),
                            const SizedBox(height: 24),
                            Obx(
                              () => AppButton(
                                label: 'Sign In',
                                isLoading: auth.isLoading.value,
                                onPressed: () async {
                                  final success = await auth.login();
                                  if (success) {
                                    Get.offAll(() => AppGroundView());
                                  } else if (auth.isEmailNotVerified.value) {
                                    showErrorSnackbar(
                                      'Email not verified. Check your inbox for the OTP or register again.',
                                    );
                                    Get.to(() => OtpVerificationScreenView());
                                  } else if (auth.errorMessage.isNotEmpty) {
                                    showErrorSnackbar(auth.errorMessage.value);
                                  }
                                },
                              ).entrance(index: 4),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: GestureDetector(
                                onTap: () =>
                                    Get.to(() => ForgotPasswordScreenView()),
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ).entrance(index: 5, enableScale: false),
                              ),
                            ),
                            const SizedBox(height: 200),
                            Center(
                              child: AuthLink(
                                text: "Don't have an account? ",
                                linkText: 'Register Now',
                                onTap: () => Get.to(() => SignupScreenView()),
                              ).entrance(index: 6, enableScale: false),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
