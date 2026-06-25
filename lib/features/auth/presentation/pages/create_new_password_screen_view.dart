import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../controller/auth_controller.dart';
import '../widgets/_auth_widgets.dart';
import 'password_changed_screen_view.dart';

class CreateNewPasswordScreenView extends StatelessWidget {
  const CreateNewPasswordScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AuthPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          AuthBackButton(),
          SizedBox(height: 48),
          Text(
            'Create New Password',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Your new password must be unique from those previously used.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          SizedBox(height: 36),
          AppTextField(
            hint: 'New Password',
            controller: auth.newPasswordController,
            isPassword: true,
          ),
          SizedBox(height: 14),
          AppTextField(
            hint: 'Confirm Password',
            controller: auth.confirmPasswordController,
            isPassword: true,
          ),
          SizedBox(height: 28),
          Obx(
            () => AppButton(
              label: 'Reset Password',
              isLoading: auth.isLoading.value,
              onPressed: () async {
                final success = await auth.resetPassword();
                if (success) {
                  Get.to(() => PasswordChangedScreenView());
                } else if (auth.errorMessage.isNotEmpty) {
                  showErrorSnackbar(auth.errorMessage.value);
                }
              },
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
