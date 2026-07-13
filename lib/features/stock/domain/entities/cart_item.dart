import 'inventory_item.dart';

/// A single row in the shopkeeper's cart: a quantity of a given
/// [InventoryItem] added ahead of building an invoice.
class CartItem {
  final String id;
  final int quantity;
  final DateTime? createdAt;
  final InventoryItem? item;

  const CartItem({
    required this.id,
    required this.quantity,
    this.createdAt,
    this.item,
  });

  double get unitPrice => item?.price ?? 0;

  double get totalPrice => unitPrice * quantity;
}
