import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';

class StockController extends GetxController {
  late final ApiClient _api;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  final categories = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _api = ApiClient(baseUrl);
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      final res = await _api.get(CategoryEndpoints.withCount);
      final data = res.data['data'];
      if (data is List) {
        categories.value = List<Map<String, dynamic>>.from(data);
      }
    } on DioException catch (e) {
      debugPrint('Categories fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createCategory({required String name, String? imagePath}) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      if (imagePath != null && imagePath.isNotEmpty) {
        final formData = FormData.fromMap({
          'name': name,
          'image': await MultipartFile.fromFile(imagePath),
        });
        await _api.dio.post(CategoryEndpoints.create, data: formData);
      } else {
        await _api.post(CategoryEndpoints.create, data: {'name': name});
      }
      await fetchCategories();
      return true;
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Failed to create category';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    String? imagePath,
  }) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      if (imagePath != null && imagePath.isNotEmpty) {
        final formData = FormData.fromMap({
          'name': name,
          'image': await MultipartFile.fromFile(imagePath),
        });
        await _api.dio.put(CategoryEndpoints.byId(id), data: formData);
      } else {
        await _api.put(CategoryEndpoints.byId(id), data: {'name': name});
      }
      await fetchCategories();
      return true;
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Failed to update category';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    errorMessage.value = '';
    try {
      await _api.delete(CategoryEndpoints.byId(id));
      categories.removeWhere((c) => c['_id'] == id);
      return true;
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Failed to delete category';
      return false;
    }
  }
}
