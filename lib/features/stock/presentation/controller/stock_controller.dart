import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/inventory_repository.dart';

class StockController extends GetxController {
  late final CategoryRepository _categoryRepo;
  late final InventoryRepository _inventoryRepo;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;

  final categories = <Category>[].obs;
  final inventoryCategoryCards = <Category>[].obs;

  @override
  void onInit() {
    super.onInit();
    final api = ApiClient(baseUrl);
    _categoryRepo = CategoryRepositoryImpl(api);
    _inventoryRepo = InventoryRepositoryImpl(api);
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

      categories.value = await _categoryRepo.getCategoriesWithCount(shopkeeperId);
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
    final cards = List<Category>.from(categories);

    try {
      final items = await _inventoryRepo.getByShopkeeperId(shopkeeperId);
      final derivedCards = _buildInventoryCategoryCards(items);
      final existingIds = cards.map((category) => category.id).toSet();
      for (final card in derivedCards) {
        if (!existingIds.contains(card.id)) {
          cards.add(card);
        }
      }
    } on DioException catch (e) {
      debugPrint('Inventory category sync error: $e');
    }

    inventoryCategoryCards.value = cards;
  }

  List<Category> _buildInventoryCategoryCards(List<InventoryItem> items) {
    final countByKey = <String, int>{};
    final templateByKey = <String, Category>{};
    final fallbackImageByKey = <String, String>{};

    for (final category in categories) {
      final id = category.id.trim();
      final name = _normalizedCategoryName(category.name);
      if (id.isNotEmpty) {
        templateByKey[id] = category;
      }
      if (name.isNotEmpty) {
        templateByKey.putIfAbsent(name, () => category);
      }
    }

    for (final item in items) {
      final categoryId = item.categoryId;
      final categoryName = _normalizedCategoryName(item.categoryName ?? '');
      final key = categoryId?.isNotEmpty == true ? categoryId! : (categoryName.isNotEmpty ? categoryName : '');
      if (key.isEmpty) continue;

      countByKey.update(key, (value) => value + 1, ifAbsent: () => 1);

      final itemImage = item.imageUrl;
      if (itemImage != null && itemImage.isNotEmpty) {
        fallbackImageByKey.putIfAbsent(key, () => itemImage);
      }

      if (!templateByKey.containsKey(key) && categoryName.isNotEmpty) {
        templateByKey[key] = Category(id: categoryId ?? '', name: item.categoryName ?? 'Category');
      }
    }

    final visibleCategories = <Category>[];

    for (final entry in countByKey.entries) {
      final template = templateByKey[entry.key] ?? Category(id: entry.key, name: 'Category');
      final imageUrl = template.imageUrl ?? fallbackImageByKey[entry.key];
      visibleCategories.add(template.copyWith(imageUrl: imageUrl, itemCount: entry.value));
    }

    visibleCategories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return visibleCategories;
  }

  String _normalizedCategoryName(String value) {
    return value.trim().toLowerCase();
  }

  Future<String?> _resolveShopkeeperId() async {
    final profileCtrl = Get.find<ProfileController>();
    var id = profileCtrl.userId.trim();
    if (id.isNotEmpty) return id;

    await profileCtrl.fetchProfile();
    id = profileCtrl.userId.trim();
    if (id.isNotEmpty) return id;

    try {
      return await _categoryRepo.getMyProfileId();
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

      await _categoryRepo.createCategory(name: name, shopkeeperId: shopkeeperId, imagePath: imagePath);
      await fetchCategories();
      return true;
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Failed to create category';
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

      await _categoryRepo.updateCategory(id: id, name: name, shopkeeperId: shopkeeperId, imagePath: imagePath);
      await fetchCategories();
      return true;
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Failed to update category';
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> deleteCategory(String id) async {
    errorMessage.value = '';
    try {
      await _categoryRepo.deleteCategory(id);
      categories.removeWhere((c) => c.id == id);
      inventoryCategoryCards.removeWhere((c) => c.id == id);
      return true;
    } on DioException catch (e) {
      errorMessage.value = e.response?.data?['message'] ?? 'Failed to delete category';
      return false;
    }
  }
}
