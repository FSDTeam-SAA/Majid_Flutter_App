import '../entities/category.dart';

abstract class CategoryRepository {
  /// Fetches all categories for [shopkeeperId] with backend-computed item
  /// counts (`CategoryEndpoints.withCount`).
  Future<List<Category>> getCategoriesWithCount(String shopkeeperId);

  Future<Category> createCategory({
    required String name,
    required String shopkeeperId,
    String? imagePath,
  });

  Future<Category> updateCategory({
    required String id,
    required String name,
    required String shopkeeperId,
    String? imagePath,
  });

  Future<void> deleteCategory(String id);

  /// Fallback lookup of the current user's id via `/user/my-profile`, used
  /// when the id isn't already available from [ProfileController].
  Future<String?> getMyProfileId();
}
