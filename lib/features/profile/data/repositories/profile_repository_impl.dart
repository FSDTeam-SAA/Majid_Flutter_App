import 'package:dio/dio.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';

UserProfile userProfileFromJson(Map<String, dynamic> json) {
  final image = json['image'];
  final imageUrl = image is Map ? image['url']?.toString() ?? '' : '';

  return UserProfile(
    id: json['_id']?.toString() ?? '',
    firstName: json['firstName']?.toString() ?? '',
    lastName: json['lastName']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    balance: (json['balance'] as num?)?.toDouble() ?? 0,
    shopName: json['shopName']?.toString() ?? '',
    shopAddress: json['shopAddress']?.toString() ?? '',
    whatsappNumber: json['whatsappNumber']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    imageUrl: imageUrl,
    currencyCode: json['currency']?.toString() ?? 'GBP',
  );
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _api;

  ProfileRepositoryImpl(this._api);

  @override
  Future<UserProfile> getProfile() async {
    final res = await _api.get(UserEndpoints.myProfile);
    return userProfileFromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? whatsappNumber,
    String? shopName,
    String? shopAddress,
    String? imagePath,
    String? currencyCode,
  }) async {
    try {
      final data = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
      };
      if (phone != null && phone.isNotEmpty) data['phone'] = phone;
      if (whatsappNumber != null && whatsappNumber.isNotEmpty) {
        data['whatsappNumber'] = whatsappNumber;
      }
      if (shopName != null) data['shopName'] = shopName;
      if (shopAddress != null) data['shopAddress'] = shopAddress;
      if (currencyCode != null) data['currency'] = currencyCode;

      final payload = imagePath != null && imagePath.isNotEmpty
          ? FormData.fromMap({
              ...data,
              'image': await MultipartFile.fromFile(imagePath),
            })
          : data;

      final res = await _api.put(UserEndpoints.updateProfile, data: payload);
      return userProfileFromJson(Map<String, dynamic>.from(res.data['data']));
    } on DioException catch (e) {
      throw ProfileException(
        _messageFromDioError(e, fallback: 'Failed to update profile'),
      );
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _api.post(
        AuthEndpoints.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw ProfileException(
        _messageFromDioError(e, fallback: 'Failed to change password'),
      );
    }
  }

  String _messageFromDioError(DioException error, {required String fallback}) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }

    if (statusCode == 404) {
      return 'API route not found. Please check the backend base URL.';
    }

    if (statusCode == 401) {
      return 'Session expired. Please login again.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to the backend server.';
    }

    return fallback;
  }
}
