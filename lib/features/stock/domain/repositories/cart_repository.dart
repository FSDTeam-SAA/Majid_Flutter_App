import '../entities/cart_item.dart';

abstract class CartRepository {
  Future<List<CartItem>> getCartItems(String shopkeeperId);

  Future<void> addToCart({
    required String shopkeeperId,
    required String itemId,
    int quantity = 1,
  });

  Future<void> deleteCartItem(String id);
}
