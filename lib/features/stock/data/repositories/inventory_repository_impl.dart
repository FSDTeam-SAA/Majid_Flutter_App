import 'package:dio/dio.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/csv_import_summary.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Parses a raw inventory item JSON object into an [InventoryItem].
///
/// Exposed at library level (not just within this file) so
/// [CartRepositoryImpl] can reuse it for the nested `itemId` inventory
/// object embedded in cart entries, instead of duplicating the same field
/// extraction logic.
InventoryItem inventoryItemFromJson(Map<String, dynamic> json) {
  final image = json['image'];
  final imageUrl = image is Map ? image['url']?.toString() : null;

  return InventoryItem(
    id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
    itemName: json['itemName']?.toString() ?? '',
    sku: json['sku']?.toString(),
    brand: json['brand']?.toString(),
    color: json['color']?.toString(),
    storage: json['storage']?.toString(),
    modelNumber: json['modelNumber']?.toString(),
    imeiNumber: json['imeiNumber']?.toString() ?? '',
    currentState: json['currentState']?.toString() ?? 'good condition',
    status: json['status']?.toString() ?? 'inventory',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    purchasePrice: json['purchasePrice'] as num?,
    expectedPrice: json['expectedPrice'] as num?,
    minStockLevel: (json['minStockLevel'] as num?)?.toInt(),
    groupKey: json['groupKey']?.toString(),
    productDetails: json['productDetails']?.toString(),
    categoryId: _categoryId(json),
    categoryName: _categoryName(json),
    imageUrl: imageUrl,
  );
}

String? _categoryId(Map<String, dynamic> item) {
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

String? _categoryName(Map<String, dynamic> item) {
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

class InventoryRepositoryImpl implements InventoryRepository {
  final ApiClient _api;

  InventoryRepositoryImpl(this._api);

  @override
  Future<List<InventoryItem>> getByShopkeeperId(String shopkeeperId) async {
    final res = await _api.get(InventoryEndpoints.byUserId(shopkeeperId));
    return _listFromResponse(res);
  }

  @override
  Future<List<InventoryItem>> getMyInventory() async {
    final res = await _api.get(InventoryEndpoints.myInventory);
    return _listFromResponse(res);
  }

  List<InventoryItem> _listFromResponse(Response res) {
    final data = res.data['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((item) => inventoryItemFromJson(Map<String, dynamic>.from(item))).toList();
  }

  @override
  Future<InventoryItem> createItem({
    required Map<String, dynamic> data,
    String? imagePath,
  }) async {
    final payload = imagePath == null || imagePath.isEmpty
        ? data
        : FormData.fromMap({...data, 'image': await MultipartFile.fromFile(imagePath)});
    final res = await _api.post(InventoryEndpoints.create, data: payload);
    return inventoryItemFromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<InventoryItem> updateItem({
    required String id,
    required Map<String, dynamic> data,
    String? imagePath,
  }) async {
    final payload = imagePath == null || imagePath.isEmpty
        ? data
        : FormData.fromMap({...data, 'image': await MultipartFile.fromFile(imagePath)});
    final res = await _api.put(InventoryEndpoints.byId(id), data: payload);
    return inventoryItemFromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<void> deleteItem(String id) async {
    await _api.delete(InventoryEndpoints.byId(id));
  }

  @override
  Future<void> createFromBarcodeBulk({
    required String currentState,
    required List<Map<String, dynamic>> items,
  }) async {
    await _api.post(
      InventoryEndpoints.createFromBarcodeBulk,
      data: {'currentState': currentState, 'items': items},
    );
  }

  @override
  Future<CsvImportSummary> importCsv({
    String? filePath,
    List<int>? fileBytes,
    required String filename,
  }) async {
    final MultipartFile uploadFile;
    if (filePath != null && filePath.isNotEmpty) {
      uploadFile = await MultipartFile.fromFile(filePath, filename: filename);
    } else if (fileBytes != null) {
      uploadFile = MultipartFile.fromBytes(fileBytes, filename: filename);
    } else {
      throw ArgumentError('Either filePath or fileBytes must be provided');
    }

    final payload = FormData.fromMap({'file': uploadFile});
    final response = await _api.post(InventoryEndpoints.importCsv, data: payload);

    final responseData = response.data;
    final responseBody = responseData is Map ? responseData['data'] : null;
    final summary = responseBody is Map ? responseBody['summary'] : null;
    final successCount = summary is Map ? (summary['successCount'] as num?)?.toInt() : null;
    final failureCount = summary is Map ? (summary['failureCount'] as num?)?.toInt() : null;

    return CsvImportSummary(successCount: successCount, failureCount: failureCount);
  }
}
