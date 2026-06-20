import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/network/api_service/token_meneger.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  late final AuthRepository _repo;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final otpControllers = List.generate(6, (_) => TextEditingController());
  final newPasswordController = TextEditingController();

  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final Rx<UserModel?> user = Rx<UserModel?>(null);

  // Tracks which flow the OTP screen is for
  final isEmailVerification = false.obs;

  @override
  void onInit() {
    super.onInit();
    _repo = AuthRepositoryImpl(ApiClient(baseUrl));
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    for (final c in otpControllers) {
      c.dispose();
    }
    newPasswordController.dispose();
    super.onClose();
  }

  String get _otpValue => otpControllers.map((c) => c.text).join();

  void _clearOtp() {
    for (final c in otpControllers) {
      c.clear();
    }
  }

  void clearError() => errorMessage.value = '';

  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    firstNameController.clear();
    lastNameController.clear();
    newPasswordController.clear();
    _clearOtp();
  }

  Future<bool> register() async {
    if (firstNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      errorMessage.value = 'Please fill all required fields';
      return false;
    }

    return _execute(() async {
      final response = await _repo.register(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      await TokenManager.saveToken(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      user.value = response.user;
      isEmailVerification.value = true;
    });
  }

  Future<bool> verifyEmail() async {
    final otp = _otpValue;
    if (otp.length < 4) {
      errorMessage.value = 'Please enter the complete OTP';
      return false;
    }

    return _execute(() async {
      await _repo.verifyEmail(otp: otp);
      _clearOtp();
    });
  }

  Future<bool> resendOtp() async {
    return _execute(() async {
      if (isEmailVerification.value) {
        await _repo.resendOtp();
      } else {
        await _repo.resendForgotOtp();
      }
    });
  }

  Future<bool> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      errorMessage.value = 'Please enter email and password';
      return false;
    }

    return _execute(() async {
      const demoToken = 'local-demo-token';
      await TokenManager.saveToken(
        accessToken: demoToken,
        refreshToken: demoToken,
      );
      user.value = UserModel(
        id: 'local-demo-user',
        firstName: 'Demo',
        lastName: 'User',
        email: emailController.text.trim(),
        role: 'user',
        isVerified: true,
      );
      _clearFields();
    });
  }

  Future<bool> forgotPassword() async {
    if (emailController.text.isEmpty) {
      errorMessage.value = 'Please enter your email';
      return false;
    }

    return _execute(() async {
      final token = await _repo.forgotPassword(
        email: emailController.text.trim(),
      );
      await TokenManager.accessToken(token);
      isEmailVerification.value = false;
    });
  }

  Future<bool> verifyForgotOtp() async {
    final otp = _otpValue;
    if (otp.length < 4) {
      errorMessage.value = 'Please enter the complete OTP';
      return false;
    }

    return _execute(() async {
      final token = await _repo.verifyOtp(otp: otp);
      await TokenManager.accessToken(token);
      _clearOtp();
    });
  }

  Future<bool> resetPassword() async {
    if (newPasswordController.text.isEmpty) {
      errorMessage.value = 'Please enter a new password';
      return false;
    }
    if (newPasswordController.text != confirmPasswordController.text) {
      errorMessage.value = 'Passwords do not match';
      return false;
    }

    return _execute(() async {
      await _repo.resetPassword(newPassword: newPasswordController.text);
      await TokenManager.clearToken();
      _clearFields();
    });
  }

  Future<void> logout() async {
    await TokenManager.clearToken();
    user.value = null;
    _clearFields();
  }

  Future<bool> _execute(Future<void> Function() action) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      await action();
      return true;
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Something went wrong';
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
