import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import 'inventory_repository_impl.dart' show inventoryItemFromJson;

class CartRepositoryImpl implements CartRepository {
  final ApiClient _api;

  CartRepositoryImpl(this._api);

  @override
  Future<List<CartItem>> getCartItems(String shopkeeperId) async {
    final res = await _api.get(CartEndpoints.byShopkeeper(shopkeeperId));
    final data = res.data['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => _cartItemFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  CartItem _cartItemFromJson(Map<String, dynamic> json) {
    final rawItem = json['itemId'];
    return CartItem(
      id: json['_id']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      item: rawItem is Map
          ? inventoryItemFromJson(Map<String, dynamic>.from(rawItem))
          : null,
    );
  }

  @override
  Future<void> addToCart({
    required String shopkeeperId,
    required String itemId,
    int quantity = 1,
  }) async {
    await _api.post(
      CartEndpoints.create,
      data: {
        'shopkeeperId': shopkeeperId,
        'itemId': itemId,
        'quantity': quantity,
      },
    );
  }

  @override
  Future<void> deleteCartItem(String id) async {
    await _api.delete(CartEndpoints.delete(id));
  }
}
