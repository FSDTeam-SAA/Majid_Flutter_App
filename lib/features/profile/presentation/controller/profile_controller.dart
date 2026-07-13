import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../stock/data/repositories/inventory_repository_impl.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/checkout_session.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends GetxController {
  late final ProfileRepository _profileRepo;
  late final PaymentRepository _paymentRepo;
  late final DashboardRepository _dashboardRepo;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  // Profile data
  final profile = Rx<UserProfile?>(null);

  // Payment history
  final payments = <Payment>[].obs;
  final isPaymentsLoading = true.obs;

  // Subscriptions
  final subscriptions = <SubscriptionPlan>[].obs;
  final isSubscriptionsLoading = true.obs;

  // Repair stats for business health (legacy - kept for fallback)
  final totalRepairs = 0.obs;
  final totalInventoryItems = 0.obs;

  // Dashboard stats
  final dashboardStats = Rx<DashboardStats?>(null);
  final isDashboardLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final api = ApiClient(baseUrl);
    _profileRepo = ProfileRepositoryImpl(api);
    _paymentRepo = PaymentRepositoryImpl(api);
    _dashboardRepo = DashboardRepositoryImpl(api, InventoryRepositoryImpl(api));
    fetchProfile();
  }

  /// True once a profile fetch has completed and returned no data — mirrors
  /// the previous `profileData.isEmpty` check used by the presentation layer.
  bool get hasNoProfile => profile.value == null;

  String get fullName => profile.value?.fullName ?? '';
  String get email => profile.value?.email ?? '';
  double get balance => profile.value?.balance ?? 0;
  String get shopName => profile.value?.shopName ?? '';
  String get shopAddress => profile.value?.shopAddress ?? '';
  String get whatsappNumber => profile.value?.whatsappNumber ?? '';
  String get phone => profile.value?.phone ?? '';
  String get userId => profile.value?.id ?? '';
  String get imageUrl => profile.value?.imageUrl ?? '';

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      profile.value = await _profileRepo.getProfile();
    } catch (e) {
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
      profile.value = await _profileRepo.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        whatsappNumber: whatsappNumber,
        shopName: shopName,
        shopAddress: shopAddress,
        imagePath: imagePath,
      );
      return true;
    } on ProfileException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to update profile';
      debugPrint('Profile update error: $e');
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
      await _profileRepo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on ProfileException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'Failed to change password';
      debugPrint('Password change error: $e');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchPayments() async {
    isPaymentsLoading.value = true;
    try {
      payments.value = await _paymentRepo.getMyPayments();
    } catch (e) {
      debugPrint('Payments fetch error: $e');
    } finally {
      isPaymentsLoading.value = false;
    }
  }

  Future<void> fetchSubscriptions() async {
    isSubscriptionsLoading.value = true;
    try {
      subscriptions.value = await _paymentRepo.getSubscriptionPlans();
    } catch (e) {
      debugPrint('Subscriptions fetch error: $e');
    } finally {
      isSubscriptionsLoading.value = false;
    }
  }

  Future<CheckoutSession> createPayment({
    required double amount,
    String? subscriptionId,
  }) {
    return _paymentRepo.createPayment(amount: amount, subscriptionId: subscriptionId);
  }

  Future<void> fetchBusinessHealthData() async {
    try {
      final stats = await _dashboardRepo.getLegacyBusinessHealthStats();
      totalRepairs.value = stats.totalRepairs;
      totalInventoryItems.value = stats.totalInventoryItems;
    } catch (e) {
      debugPrint('Business health fetch error: $e');
    }
  }

  Future<void> fetchDashboardStats({String filter = 'monthly'}) async {
    isDashboardLoading.value = true;
    try {
      final id = userId;
      dashboardStats.value = await _dashboardRepo.getStats(
        filter: filter,
        shopkeeperId: id.isNotEmpty ? id : null,
      );
    } catch (e) {
      debugPrint('Dashboard stats fetch error: $e');
    } finally {
      isDashboardLoading.value = false;
    }
  }
}
