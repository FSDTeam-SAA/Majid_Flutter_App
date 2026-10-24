import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/animation/app_entrance.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../app_ground_view.dart';
import '../../../security/presentation/sign_in_security_flow.dart';
import '../controller/auth_controller.dart';
import '../widgets/_auth_widgets.dart';
import 'signup_screen_view.dart';
import 'forgot_password_screen_view.dart';
import 'otp_verification_screen_view.dart';

import '../../../../core/services/biometric_service.dart';

class LoginScreenView extends StatefulWidget {
  const LoginScreenView({super.key});

  @override
  State<LoginScreenView> createState() => _LoginScreenViewState();
}

class _LoginScreenViewState extends State<LoginScreenView> {
  final BiometricService _biometrics = BiometricService.instance;
  DeviceBiometricType _biometricType = DeviceBiometricType.none;
  bool _canUseBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final type = await _biometrics.getPrimaryBiometricType();
    final canCheck = await _biometrics.canCheckBiometrics();

    if (mounted) {
      setState(() {
        _biometricType = type;
        _canUseBiometrics = canCheck && type != DeviceBiometricType.none;
      });
    }
  }

  Future<void> _handleBiometricLogin(
      BuildContext context, AuthController auth) async {
    final creds = await _biometrics.getSavedCredentials();
    if (creds == null) {
      showErrorSnackbar(
        'Please sign in with your email and password first. Biometric login will then be available on your next visits.',
      );
      return;
    }

    final label = _biometrics.getBiometricLabel(_biometricType);
    final error = await _biometrics.authenticateWithResult(
      localizedReason: 'Scan your $label to sign in to Imoscan',
    );

    if (error != null) {
      showErrorSnackbar(error);
      return;
    }

    final success = await auth.loginWithCredentials(
      email: creds['email']!,
      password: creds['password']!,
    );

    if (success) {
      if (!context.mounted) return;
      final cleared = await SignInSecurityFlow.run(context);
      if (!cleared) {
        await auth.logout();
        showErrorSnackbar('Sign-in was not completed');
        return;
      }
      Get.offAll(() => AppGroundView());
    } else if (auth.isEmailNotVerified.value) {
      showErrorSnackbar(
        'Email not verified. Check your inbox for the OTP or register again.',
      );
      Get.to(() => OtpVerificationScreenView());
    } else if (auth.errorMessage.isNotEmpty) {
      showErrorSnackbar(auth.errorMessage.value);
    }
  }

  IconData get _biometricIcon {
    switch (_biometricType) {
      case DeviceBiometricType.face:
        return Icons.face_rounded;
      case DeviceBiometricType.fingerprint:
      case DeviceBiometricType.multiple:
      case DeviceBiometricType.generic:
      case DeviceBiometricType.none:
        return Icons.fingerprint_rounded;
    }
  }

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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 56),
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
                            const SizedBox(height: 36),
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
                                    if (!context.mounted) return;
                                    final cleared =
                                        await SignInSecurityFlow.run(context);
                                    if (!cleared) {
                                      await auth.logout();
                                      showErrorSnackbar(
                                        'Sign-in was not completed',
                                      );
                                      return;
                                    }
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
                            if (_canUseBiometrics) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: auth.isLoading.value
                                      ? null
                                      : () => _handleBiometricLogin(
                                          context, auth),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    foregroundColor: AppColors.primary,
                                  ),
                                  icon: Icon(
                                    _biometricIcon,
                                    size: 22,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    'Sign In with ${_biometrics.getBiometricLabel(_biometricType)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ).entrance(index: 5),
                            ],
                            const SizedBox(height: 18),
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
                                ).entrance(index: 6, enableScale: false),
                              ),
                            ),
                            const SizedBox(height: 80),
                            Center(
                              child: AuthLink(
                                text: "Don't have an account? ",
                                linkText: 'Register Now',
                                onTap: () => Get.to(() => SignupScreenView()),
                              ).entrance(index: 7, enableScale: false),
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
