import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/scheduler.dart';
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
    // Pages kick this off from initState and GetX calls it from onInit, both
    // of which run inside the build phase. Writing to an observable there
    // marks every listening Obx dirty mid-build, which Flutter throws on, so
    // wait for the frame to finish before touching any rx value.
    await _leaveBuildPhase();
    isLoading.value = true;
    try {
      final shopkeeperId = await _resolveShopkeeperId();
      if (shopkeeperId == null) {
        categories.clear();
        inventoryCategoryCards.clear();
        return;
      }

      categories.value = await _categoryRepo.getCategoriesWithCount(
        shopkeeperId,
      );
      await _refreshInventoryCategoryCards(shopkeeperId);
    } catch (e) {
      // Kept non-fatal (the grid simply shows what it already had), but the
      // reason is recorded rather than swallowed — a failing list endpoint
      // used to look exactly like "there are no categories".
      errorMessage.value = _apiErrorMessage(e, 'Failed to load categories');
    } finally {
      isLoading.value = false;
    }
  }

  /// Yields until the running frame is done when called during a build.
  Future<void> _leaveBuildPhase() async {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      await SchedulerBinding.instance.endOfFrame;
    }
  }

  Future<void> _refreshInventoryCategoryCards(String shopkeeperId) async {
    // Categories already carry backend-computed item counts, so they are the
    // primary source of truth for the grid. All categories are shown here
    // (even empty ones) so a newly created category is immediately tappable
    // to add its first device, matching the Manage Categories list.
    final baseCategories = List<Category>.from(categories);

    try {
      final items = await _inventoryRepo.getByShopkeeperId(shopkeeperId);
      final derivedCards = _buildInventoryCategoryCards(items);

      final derivedMapById = {
        for (final c in derivedCards)
          if (c.id.isNotEmpty) c.id: c,
      };
      final derivedMapByName = {
        for (final c in derivedCards)
          _normalizedCategoryName(c.name): c,
      };

      final updatedCards = <Category>[];
      for (final cat in baseCategories) {
        final match = derivedMapById[cat.id] ??
            derivedMapByName[_normalizedCategoryName(cat.name)];
        if (match != null) {
          final effectiveCount = match.itemCount > 0 ? match.itemCount : cat.itemCount;
          final effectiveImage = (cat.imageUrl != null && cat.imageUrl!.isNotEmpty)
              ? cat.imageUrl
              : match.imageUrl;
          updatedCards.add(
            cat.copyWith(itemCount: effectiveCount, imageUrl: effectiveImage),
          );
        } else {
          updatedCards.add(cat);
        }
      }

      final existingIds = updatedCards.map((c) => c.id).toSet();
      final existingNames =
          updatedCards.map((c) => _normalizedCategoryName(c.name)).toSet();
      for (final card in derivedCards) {
        if (!existingIds.contains(card.id) &&
            !existingNames.contains(_normalizedCategoryName(card.name))) {
          updatedCards.add(card);
        }
      }

      inventoryCategoryCards.value = updatedCards;
      return;
    } on DioException catch (e) {
      debugPrint('Inventory category sync error: $e');
    }

    inventoryCategoryCards.value = baseCategories;
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
      final key = categoryId?.isNotEmpty == true
          ? categoryId!
          : (categoryName.isNotEmpty ? categoryName : '');
      if (key.isEmpty) continue;

      countByKey.update(key, (value) => value + 1, ifAbsent: () => 1);

      final itemImage = item.imageUrl;
      if (itemImage != null && itemImage.isNotEmpty) {
        fallbackImageByKey.putIfAbsent(key, () => itemImage);
      }

      if (!templateByKey.containsKey(key) && categoryName.isNotEmpty) {
        templateByKey[key] = Category(
          id: categoryId ?? '',
          name: item.categoryName ?? 'Category',
        );
      }
    }

    final visibleCategories = <Category>[];

    for (final entry in countByKey.entries) {
      final template =
          templateByKey[entry.key] ?? Category(id: entry.key, name: 'Category');
      final imageUrl = template.imageUrl ?? fallbackImageByKey[entry.key];
      visibleCategories.add(
        template.copyWith(imageUrl: imageUrl, itemCount: entry.value),
      );
    }

    visibleCategories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

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

  Future<Category?> createCategory({required String name, String? imagePath}) async {
    isSaving.value = true;
    errorMessage.value = '';
    try {
      final shopkeeperId = await _resolveShopkeeperId();
      if (shopkeeperId == null) {
        errorMessage.value = 'Unable to identify current user';
        return null;
      }

      final created = await _categoryRepo.createCategory(
        name: name,
        shopkeeperId: shopkeeperId,
        imagePath: imagePath,
      );
      await fetchCategories();
      return created;
    } catch (e) {
      errorMessage.value = _apiErrorMessage(e, 'Failed to create category');
      return null;
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

      await _categoryRepo.updateCategory(
        id: id,
        name: name,
        shopkeeperId: shopkeeperId,
        imagePath: imagePath,
      );
      await fetchCategories();
      return true;
    } catch (e) {
      errorMessage.value = _apiErrorMessage(e, 'Failed to update category');
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
    } catch (e) {
      errorMessage.value = _apiErrorMessage(e, 'Failed to delete category');
      return false;
    }
  }

  /// Turns any thrown error into something a user can act on. The backend
  /// replies `{success, message, errorSources}`, but a gateway or a crash can
  /// return HTML or a plain string instead, so every shape is handled here —
  /// previously `e.response?.data?['message']` threw a second time on those,
  /// which escaped the catch block and left the UI with no feedback at all.
  String _apiErrorMessage(Object error, String fallback) {
    debugPrint('$fallback: $error');

    if (error is! DioException) return fallback;

    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();

      final sources = data['errorSources'];
      if (sources is List && sources.isNotEmpty) {
        final first = sources.first;
        if (first is Map) {
          final sourceMessage = first['message'];
          if (sourceMessage is String && sourceMessage.trim().isNotEmpty) {
            return sourceMessage.trim();
          }
        }
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Network error — check your connection and try again';
      default:
        final status = error.response?.statusCode;
        return status == null ? fallback : '$fallback (HTTP $status)';
    }
  }
}
