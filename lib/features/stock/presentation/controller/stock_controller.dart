import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../profile/presentation/controller/profile_controller.dart';

class StockController extends GetxController {
  late final ApiClient _api;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  final categories = <Map<String, dynamic>>[].obs;
  final inventoryCategoryCards = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _api = ApiClient(baseUrl);
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    isLoading.value = true;
    try {
      final shopkeeperId = await _resolveShopkeeperId();
      if (shopkeeperId == null) {
        categories.clear();
        inventoryCategoryCards.clear();
        return;
      }

      final res = await _api.get(
        '${CategoryEndpoints.withCount}?shopkeeperId=$shopkeeperId',
      );
      final data = res.data['data'];
      if (data is List) {
        categories.value = List<Map<String, dynamic>>.from(data);
      }
      await _refreshInventoryCategoryCards(shopkeeperId);
    } on DioException catch (e) {
      debugPrint('Categories fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshInventoryCategoryCards(String shopkeeperId) async {
    // Categories already carry backend-computed item counts, so they are the
    // primary source of truth for the grid. All categories are shown here
    // (even empty ones) so a newly created category is immediately tappable
    // to add its first device, matching the Manage Categories list.
    final cards = categories
        .map((category) => Map<String, dynamic>.from(category))
        .toList();

    try {
      final res = await _api.get(InventoryEndpoints.byUserId(shopkeeperId));
      final data = res.data['data'];
      final items = data is List
          ? List<Map<String, dynamic>>.from(data)
          : <Map<String, dynamic>>[];
      final derivedCards = _buildInventoryCategoryCards(items);
      final existingIds = cards
          .map((category) => category['_id']?.toString())
          .whereType<String>()
          .toSet();
      for (final card in derivedCards) {
        final id = card['_id']?.toString();
        if (id == null || !existingIds.contains(id)) {
          cards.add(card);
        }
      }
    } on DioException catch (e) {
      debugPrint('Inventory category sync error: $e');
    }

    inventoryCategoryCards.value = cards;
  }

  List<Map<String, dynamic>> _buildInventoryCategoryCards(
    List<Map<String, dynamic>> items,
  ) {
    final countByKey = <String, int>{};
    final templateByKey = <String, Map<String, dynamic>>{};
    final fallbackImageByKey = <String, String>{};

    for (final category in categories) {
      final id = category['_id']?.toString().trim() ?? '';
      final name = _normalizedCategoryName(category['name']?.toString());
      if (id.isNotEmpty) {
        templateByKey[id] = category;
      }
      if (name.isNotEmpty) {
        templateByKey.putIfAbsent(name, () => category);
      }
    }

    for (final item in items) {
      final categoryId = _itemCategoryId(item);
      final categoryName = _normalizedCategoryName(_itemCategoryName(item));
      final key = categoryId?.isNotEmpty == true
          ? categoryId!
          : (categoryName.isNotEmpty ? categoryName : '');
      if (key.isEmpty) continue;

      countByKey.update(key, (value) => value + 1, ifAbsent: () => 1);

      final itemImage = _itemImageUrl(item);
      if (itemImage != null && itemImage.isNotEmpty) {
        fallbackImageByKey.putIfAbsent(key, () => itemImage);
      }

      if (!templateByKey.containsKey(key) && categoryName.isNotEmpty) {
        templateByKey[key] = {
          '_id': categoryId,
          'name': _itemCategoryName(item) ?? 'Category',
        };
      }
    }

    final visibleCategories = <Map<String, dynamic>>[];

    for (final entry in countByKey.entries) {
      final template = Map<String, dynamic>.from(templateByKey[entry.key] ?? {});
      final imageUrl = fallbackImageByKey[entry.key];
      if ((template['image'] == null || template['image']['url'] == null) &&
          imageUrl != null) {
        template['image'] = {'url': imageUrl};
      }
      template['itemCount'] = entry.value;
      template['totalItems'] = entry.value;
      visibleCategories.add(template);
    }

    visibleCategories.sort((a, b) {
      final aName = a['name']?.toString() ?? '';
      final bName = b['name']?.toString() ?? '';
      return aName.toLowerCase().compareTo(bName.toLowerCase());
    });

    return visibleCategories;
  }

  String? _itemCategoryId(Map<String, dynamic> item) {
    final categoryId = item['categoryId'];
    if (categoryId is String && categoryId.trim().isNotEmpty) {
      return categoryId.trim();
    }
    if (categoryId is Map) {
      final nestedId = categoryId['_id']?.toString().trim();
      if (nestedId != null && nestedId.isNotEmpty) return nestedId;
    }
    final category = item['category'];
    if (category is Map) {
      final nestedId = category['_id']?.toString().trim();
      if (nestedId != null && nestedId.isNotEmpty) return nestedId;
    }
    return null;
  }

  String? _itemCategoryName(Map<String, dynamic> item) {
    final categoryName = item['categoryName'];
    if (categoryName is String && categoryName.trim().isNotEmpty) {
      return categoryName.trim();
    }

    final categoryId = item['categoryId'];
    if (categoryId is Map) {
      final nestedName = categoryId['name'];
      if (nestedName is String && nestedName.trim().isNotEmpty) {
        return nestedName.trim();
      }
    }

    final category = item['category'];
    if (category is Map) {
      final nestedName = category['name'];
      if (nestedName is String && nestedName.trim().isNotEmpty) {
        return nestedName.trim();
      }
    }

    if (category is String && category.trim().isNotEmpty) {
      return category.trim();
    }

    return null;
  }

  String? _itemImageUrl(Map<String, dynamic> item) {
    final image = item['image'];
    if (image is Map) {
      final url = image['url']?.toString().trim();
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  String _normalizedCategoryName(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  Future<String?> _resolveShopkeeperId() async {
    final profileCtrl = Get.find<ProfileController>();
    var id = profileCtrl.userId.trim();
    if (id.isNotEmpty) return id;

    await profileCtrl.fetchProfile();
    id = profileCtrl.userId.trim();
    if (id.isNotEmpty) return id;

    try {
      final res = await _api.get(UserEndpoints.myProfile);
      final data = res.data['data'];
      final resolvedId = data['_id']?.toString().trim() ?? '';
      return resolvedId.isEmpty ? null : resolvedId;
    } on DioException catch (e) {
      debugPrint('Profile resolve error: $e');
      return null;
    }
  }

  Future<bool> createCategory({required String name, String? imagePath}) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      final shopkeeperId = await _resolveShopkeeperId();
      if (shopkeeperId == null) {
        errorMessage.value = 'Unable to identify current user';
        return false;
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        final formData = FormData.fromMap({
          'name': name,
          'shopkeeperId': shopkeeperId,
          'image': await MultipartFile.fromFile(imagePath),
        });
        await _api.dio.post(CategoryEndpoints.create, data: formData);
      } else {
        await _api.post(
          CategoryEndpoints.create,
          data: {'name': name, 'shopkeeperId': shopkeeperId},
        );
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
      final shopkeeperId = await _resolveShopkeeperId();
      if (shopkeeperId == null) {
        errorMessage.value = 'Unable to identify current user';
        return false;
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        final formData = FormData.fromMap({
          'name': name,
          'shopkeeperId': shopkeeperId,
          'image': await MultipartFile.fromFile(imagePath),
        });
        await _api.dio.put(CategoryEndpoints.byId(id), data: formData);
      } else {
        await _api.put(
          CategoryEndpoints.byId(id),
          data: {'name': name, 'shopkeeperId': shopkeeperId},
        );
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
      inventoryCategoryCards.removeWhere((c) => c['_id'] == id);
      return true;
    } on DioException catch (e) {
      errorMessage.value =
          e.response?.data?['message'] ?? 'Failed to delete category';
      return false;
    }
  }
}
