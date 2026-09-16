import 'package:dio/dio.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

Category categoryFromJson(Map<String, dynamic> json) {
  final image = json['image'];
  final imageUrl = image is Map ? image['url']?.toString() : null;
  final itemCount =
      (json['itemCount'] as num?) ?? (json['totalItems'] as num?) ?? 0;

  return Category(
    id: json['_id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Category',
    imageUrl: imageUrl,
    itemCount: itemCount.toInt(),
  );
}

class CategoryRepositoryImpl implements CategoryRepository {
  final ApiClient _api;

  CategoryRepositoryImpl(this._api);

  @override
  Future<List<Category>> getCategoriesWithCount(String shopkeeperId) async {
    // Deliberately NOT `CategoryEndpoints.withCount`: that endpoint returns
    // 500 ("unknown top level operator: $eq") because its $lookup sub-pipeline
    // passes aggregation expressions to $match without wrapping them in $expr.
    // Every category fetch failed on it, so the grid stayed empty and newly
    // created categories never showed up even though the POST had succeeded.
    // The plain list endpoint is shop-scoped the same way and carries
    // `totalItems`, and StockController recomputes live counts from inventory
    // anyway. Switch back once the backend aggregation is fixed.
    final res = await _api.get(
      '${CategoryEndpoints.all}?shopkeeperId=$shopkeeperId',
    );
    final data = res.data is Map ? res.data['data'] : null;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => categoryFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<Category> createCategory({
    required String name,
    required String shopkeeperId,
    String? imagePath,
  }) async {
    final res = await _api.post(
      CategoryEndpoints.create,
      data: await _payload(name, shopkeeperId, imagePath),
    );
    return _categoryFromResponse(res.data, name);
  }

  @override
  Future<Category> updateCategory({
    required String id,
    required String name,
    required String shopkeeperId,
    String? imagePath,
  }) async {
    final res = await _api.put(
      CategoryEndpoints.byId(id),
      data: await _payload(name, shopkeeperId, imagePath),
    );
    return _categoryFromResponse(res.data, name);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _api.delete(CategoryEndpoints.byId(id));
  }

  @override
  Future<String?> getMyProfileId() async {
    final res = await _api.get(UserEndpoints.myProfile);
    final data = res.data['data'];
    final resolvedId = data is Map ? data['_id']?.toString().trim() ?? '' : '';
    return resolvedId.isEmpty ? null : resolvedId;
  }

  /// The write endpoints normally echo the saved category under `data`, but
  /// some replies wrap it one level deeper or omit it entirely. The HTTP call
  /// already succeeded by this point, so an unexpected shape must not blow up
  /// with a cast error — fall back to what we sent and let the list refresh
  /// fill in the server's version.
  Category _categoryFromResponse(dynamic body, String name) {
    final data = body is Map ? body['data'] : null;
    if (data is! Map) return Category(id: '', name: name);

    final nested = data['category'];
    final json = nested is Map ? nested : data;
    return categoryFromJson(Map<String, dynamic>.from(json));
  }

  Future<dynamic> _payload(
    String name,
    String shopkeeperId,
    String? imagePath,
  ) async {
    if (imagePath == null || imagePath.isEmpty) {
      return {'name': name, 'shopkeeperId': shopkeeperId};
    }
    return FormData.fromMap({
      'name': name,
      'shopkeeperId': shopkeeperId,
      'image': await MultipartFile.fromFile(imagePath),
    });
  }
}
