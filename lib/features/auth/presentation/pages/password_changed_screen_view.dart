import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import 'login_screen_view.dart';

class PasswordChangedScreenView extends StatelessWidget {
  const PasswordChangedScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreenView()),
                    (route) => false,
                  ),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(10),
                      color: AppColors.fieldBackground,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 16),
                  ),
                ),
                const Spacer(),
                // Success icon
                Center(
                  child: SizedBox(width: 100, height: 100, child: Image.asset('assets/images/sucessicon.png', fit: BoxFit.contain)),
                ),
                const SizedBox(height: 36),
                const Center(
                  child: Text(
                    'Password Changed!',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Your password has been changed\nsuccessfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'Back to Login',
                  onPressed: () =>
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreenView()), (route) => false),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
