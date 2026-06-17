import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<AuthResponseModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<Map<String, dynamic>> verifyEmail({required String otp});

  Future<void> resendOtp();

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<String> forgotPassword({required String email});

  Future<void> resendForgotOtp();

  Future<String> verifyOtp({required String otp});

  Future<void> resetPassword({required String newPassword});

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
