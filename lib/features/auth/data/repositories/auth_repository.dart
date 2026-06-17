import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<AuthResponseModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      UserEndpoints.register,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      },
    );
    return AuthResponseModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> verifyEmail({required String otp}) async {
    final response = await _api.post(
      UserEndpoints.verifyEmail,
      data: {'otp': otp},
    );
    return response.data;
  }

  Future<void> resendOtp() async {
    await _api.post(UserEndpoints.resendOtp);
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      AuthEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponseModel.fromJson(response.data['data']);
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await _api.post(
      AuthEndpoints.forgotPassword,
      data: {'email': email},
    );
    return response.data['data']['accessToken'];
  }

  Future<void> resendForgotOtp() async {
    await _api.post(AuthEndpoints.resendForgotOtp);
  }

  Future<String> verifyOtp({required String otp}) async {
    final response = await _api.post(
      AuthEndpoints.verifyOtp,
      data: {'otp': otp},
    );
    return response.data['data']['accessToken'];
  }

  Future<void> resetPassword({required String newPassword}) async {
    await _api.post(
      AuthEndpoints.resetPassword,
      data: {'newPassword': newPassword},
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post(
      AuthEndpoints.changePassword,
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
