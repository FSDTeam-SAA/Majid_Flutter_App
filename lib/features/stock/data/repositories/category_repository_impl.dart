import 'package:dio/dio.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

Category categoryFromJson(Map<String, dynamic> json) {
  final image = json['image'];
  final imageUrl = image is Map ? image['url']?.toString() : null;
  final itemCount = (json['itemCount'] as num?) ?? (json['totalItems'] as num?) ?? 0;

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
    final res = await _api.get('${CategoryEndpoints.withCount}?shopkeeperId=$shopkeeperId');
    final data = res.data['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((item) => categoryFromJson(Map<String, dynamic>.from(item))).toList();
  }

  @override
  Future<Category> createCategory({
    required String name,
    required String shopkeeperId,
    String? imagePath,
  }) async {
    final res = await _api.post(CategoryEndpoints.create, data: await _payload(name, shopkeeperId, imagePath));
    return categoryFromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<Category> updateCategory({
    required String id,
    required String name,
    required String shopkeeperId,
    String? imagePath,
  }) async {
    final res = await _api.put(CategoryEndpoints.byId(id), data: await _payload(name, shopkeeperId, imagePath));
    return categoryFromJson(Map<String, dynamic>.from(res.data['data']));
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

  Future<dynamic> _payload(String name, String shopkeeperId, String? imagePath) async {
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
