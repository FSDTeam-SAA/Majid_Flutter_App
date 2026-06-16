import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/_auth_widgets.dart';
import 'signup_screen_view.dart';
import 'forgot_password_screen_view.dart';
import '../../../../app_ground_view.dart';

class LoginScreenView extends StatelessWidget {
  const LoginScreenView({super.key});

  @override
  Widget build(BuildContext context) {
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
                //  const AuthBackButton(),
                const SizedBox(height: 48),
                const Text(
                  'Welcome Back to',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const ImoscanTitle(),
                const SizedBox(height: 40),
                const AppTextField(hint: 'Enter your email', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                const AppTextField(hint: 'Enter your password', isPassword: true),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Sign In',
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AppGroundView())),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreenView())),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: AuthLink(
                    text: "Don't have an account? ",
                    linkText: 'Register Now',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreenView())),
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
