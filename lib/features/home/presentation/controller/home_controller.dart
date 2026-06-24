import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';

class HomeController extends GetxController {
  late final ApiClient _api;

  final isLoading = true.obs;
  final errorMessage = ''.obs;

  // Profile
  final userName = ''.obs;
  final userImage = ''.obs;

  // Stats
  final totalInventoryItems = 0.obs;
  final totalSoldProducts = 0.obs;
  final totalRepairRequests = 0.obs;
  final totalCategories = 0.obs;

  // Sold inventory items (top selling)
  final soldProducts = <Map<String, dynamic>>[].obs;

  // Inventory items
  final inventoryItems = <Map<String, dynamic>>[].obs;

  // Repair requests
  final repairRequests = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _api = ApiClient(baseUrl);
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await Future.wait([
        _fetchProfile(),
        _fetchInventory(),
        _fetchSoldItems(),
        _fetchRepairRequests(),
        _fetchCategories(),
      ]);
    } catch (e) {
      debugPrint('HomeController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _api.get(UserEndpoints.myProfile);
      final data = res.data['data'];
      if (data != null) {
        final first = data['firstName'] ?? '';
        final last = data['lastName'] ?? '';
        userName.value = '$first $last'.trim();
        final img = data['image'];
        if (img is Map && img['url'] != null) {
          userImage.value = img['url'];
        }
      }
    } on DioException catch (e) {
      debugPrint('Profile fetch error: $e');
    }
  }

  Future<void> _fetchInventory() async {
    try {
      final res = await _api.get(InventoryEndpoints.myInventory);
      final data = res.data['data'];
      if (data is List) {
        inventoryItems.value = List<Map<String, dynamic>>.from(data);
        totalInventoryItems.value = data.length;
      }
    } on DioException catch (e) {
      debugPrint('Inventory fetch error: $e');
    }
  }

  Future<void> _fetchSoldItems() async {
    try {
      final res = await _api.get(InventoryEndpoints.soldItems);
      final data = res.data['data'];
      if (data is List) {
        final items = List<Map<String, dynamic>>.from(data);
        soldProducts.value = items;
        totalSoldProducts.value = items.length;
      }
    } on DioException catch (e) {
      debugPrint('Sold items fetch error: $e');
    }
  }

  Future<void> _fetchRepairRequests() async {
    try {
      final res = await _api.get(RepairRequestEndpoints.myHistory);
      final data = res.data['data'];
      if (data is List) {
        repairRequests.value = List<Map<String, dynamic>>.from(data);
        totalRepairRequests.value = res.data['meta']?['total'] ?? data.length;
      }
    } on DioException catch (e) {
      debugPrint('Repair requests fetch error: $e');
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await _api.get(CategoryEndpoints.withCount);
      final data = res.data['data'];
      if (data is List) {
        totalCategories.value = data.length;
      }
    } on DioException catch (e) {
      debugPrint('Categories fetch error: $e');
    }
  }
}
