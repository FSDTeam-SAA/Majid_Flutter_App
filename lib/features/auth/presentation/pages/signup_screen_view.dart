import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../widgets/_auth_widgets.dart';

class SignupScreenView extends StatelessWidget {
  const SignupScreenView({super.key});

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
                const AuthBackButton(),
                const SizedBox(height: 36),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Create Your ',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'Imo',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'scan',
                        style: TextStyle(color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '\nAccount',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const AppTextField(hint: 'Full Name'),
                const SizedBox(height: 14),
                const AppTextField(hint: 'Enter your email', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                const AppTextField(hint: "WhatsApp Number", keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                const AppTextField(hint: 'Shop Name'),
                const SizedBox(height: 14),
                const AppTextField(hint: 'Shop Address'),
                const SizedBox(height: 14),
                const AppTextField(hint: 'Password', isPassword: true),
                const SizedBox(height: 14),
                const AppTextField(hint: 'Confirm Password', isPassword: true),
                const SizedBox(height: 28),
                AppButton(label: 'Create Account', onPressed: () {}),
                const SizedBox(height: 20),
                Center(
                  child: AuthLink(
                    text: 'Already have an account? ',
                    linkText: 'Log in now',
                    onTap: () => Navigator.pop(context),
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
