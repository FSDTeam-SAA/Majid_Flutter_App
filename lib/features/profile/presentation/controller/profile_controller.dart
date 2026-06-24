import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';

class ProfileController extends GetxController {
  late final ApiClient _api;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  // Profile data
  final profileData = <String, dynamic>{}.obs;

  // Payment history
  final payments = <Map<String, dynamic>>[].obs;
  final isPaymentsLoading = true.obs;

  // Subscriptions
  final subscriptions = <Map<String, dynamic>>[].obs;
  final isSubscriptionsLoading = true.obs;

  // Repair stats for business health
  final totalRepairs = 0.obs;
  final totalInventoryItems = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _api = ApiClient(baseUrl);
    fetchProfile();
  }

  String get fullName {
    final first = profileData['firstName'] ?? '';
    final last = profileData['lastName'] ?? '';
    return '$first $last'.trim();
  }

  String get email => profileData['email'] ?? '';
  double get balance => (profileData['balance'] ?? 0).toDouble();
  String get shopName => profileData['shopName'] ?? '';
  String get shopAddress => profileData['shopAddress'] ?? '';
  String get whatsappNumber => profileData['whatsappNumber'] ?? '';
  String get phone => profileData['phone'] ?? '';
  String get userId => profileData['_id'] ?? '';
  String get imageUrl {
    final img = profileData['image'];
    if (img is Map && img['url'] != null) return img['url'];
    return '';
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final res = await _api.get(UserEndpoints.myProfile);
      final data = res.data['data'];
      if (data != null) {
        profileData.value = Map<String, dynamic>.from(data);
      }
    } on DioException catch (e) {
      debugPrint('Profile fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? whatsappNumber,
    String? shopName,
    String? shopAddress,
    String? imagePath,
  }) async {
    isSaving.value = true;
    errorMessage.value = '';
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

      final payload = imagePath != null && imagePath.isNotEmpty
          ? FormData.fromMap({
              ...data,
              'image': await MultipartFile.fromFile(imagePath),
            })
          : data;

      final res = await _api.put(UserEndpoints.updateProfile, data: payload);
      final updated = res.data['data'];
      if (updated != null) {
        profileData.value = Map<String, dynamic>.from(updated);
      }
      return true;
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Failed to update profile';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await _api.post(
        AuthEndpoints.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return true;
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Failed to change password';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchPayments() async {
    isPaymentsLoading.value = true;
    try {
      final res = await _api.get(PaymentEndpoints.myPayments);
      final data = res.data['data'];
      if (data is List) {
        payments.value = List<Map<String, dynamic>>.from(data);
      }
    } on DioException catch (e) {
      debugPrint('Payments fetch error: $e');
    } finally {
      isPaymentsLoading.value = false;
    }
  }

  Future<void> fetchSubscriptions() async {
    isSubscriptionsLoading.value = true;
    try {
      final res = await _api.get(SubscriptionEndpoints.all);
      final data = res.data['data'];
      if (data is List) {
        subscriptions.value = List<Map<String, dynamic>>.from(data);
      }
    } on DioException catch (e) {
      debugPrint('Subscriptions fetch error: $e');
    } finally {
      isSubscriptionsLoading.value = false;
    }
  }

  Future<void> fetchBusinessHealthData() async {
    try {
      final results = await Future.wait([
        _api.get(RepairRequestEndpoints.myHistory),
        _api.get(InventoryEndpoints.myInventory),
      ]);

      final repairData = results[0].data;
      totalRepairs.value =
          repairData['meta']?['total'] ??
          (repairData['data'] is List ? repairData['data'].length : 0);

      final inventoryData = results[1].data['data'];
      if (inventoryData is List) {
        totalInventoryItems.value = inventoryData.length;
      }
    } on DioException catch (e) {
      debugPrint('Business health fetch error: $e');
    }
  }
}
