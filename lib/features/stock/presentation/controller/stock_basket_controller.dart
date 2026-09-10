import 'package:get/get.dart';

import '../../domain/entities/inventory_item.dart';

/// One product queued for checkout from the Stock section.
///
/// [newPrice] starts at the stock price and is what the shopkeeper edits on
/// the Checkout Review screen; [originalPrice] is kept so the discount and its
/// percentage can always be shown next to the edited figure.
class StockBasketLine {
  final InventoryItem item;
  final int quantity;
  final double originalPrice;
  final double newPrice;

  const StockBasketLine({
    required this.item,
    required this.quantity,
    required this.originalPrice,
    required this.newPrice,
  });

  StockBasketLine copyWith({int? quantity, double? newPrice}) {
    return StockBasketLine(
      item: item,
      quantity: quantity ?? this.quantity,
      originalPrice: originalPrice,
      newPrice: newPrice ?? this.newPrice,
    );
  }

  double get lineOriginalTotal => originalPrice * quantity;

  double get lineTotal => newPrice * quantity;

  /// Money taken off this line. Mark-ups return 0 rather than a negative
  /// discount, so the summary never shows a "discount" that raises the total.
  double get discount {
    final diff = lineOriginalTotal - lineTotal;
    return diff > 0 ? diff : 0;
  }

  /// Discount as a percentage of the original price, or null when the price
  /// has not been reduced.
  double? get discountPercent {
    if (discount <= 0 || lineOriginalTotal <= 0) return null;
    return discount / lineOriginalTotal * 100;
  }
}

/// Holds what the Stock section has sent to Checkout Review.
///
/// Stock quantities are deliberately NOT decremented here — the developer
/// notes are explicit that "stock quantity reduces only after payment is
/// successfully completed", so this basket is purely a staging area.
class StockBasketController extends GetxController {
  final lines = <StockBasketLine>[].obs;

  static StockBasketController get instance {
    if (!Get.isRegistered<StockBasketController>()) {
      Get.put(StockBasketController(), permanent: true);
    }
    return Get.find<StockBasketController>();
  }

  int get totalQuantity =>
      lines.fold<int>(0, (sum, line) => sum + line.quantity);

  double get subtotal =>
      lines.fold<double>(0, (sum, line) => sum + line.lineOriginalTotal);

  double get discountTotal =>
      lines.fold<double>(0, (sum, line) => sum + line.discount);

  double get total => lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  /// Adds [item], merging into an existing line for the same product so the
  /// review screen shows one row per product rather than one row per tap.
  void add(InventoryItem item, {int quantity = 1}) {
    final index = lines.indexWhere((line) => line.item.id == item.id);
    if (index >= 0) {
      final existing = lines[index];
      lines[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      lines.add(
        StockBasketLine(
          item: item,
          quantity: quantity,
          originalPrice: item.price,
          newPrice: item.price,
        ),
      );
    }
    lines.refresh();
  }

  void updateQuantity(String itemId, int quantity) {
    final index = lines.indexWhere((line) => line.item.id == itemId);
    if (index < 0) return;
    if (quantity <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(quantity: quantity);
    }
    lines.refresh();
  }

  void updatePrice(String itemId, double newPrice) {
    final index = lines.indexWhere((line) => line.item.id == itemId);
    if (index < 0) return;
    lines[index] = lines[index].copyWith(newPrice: newPrice);
    lines.refresh();
  }

  void remove(String itemId) {
    lines.removeWhere((line) => line.item.id == itemId);
    lines.refresh();
  }

  void clear() => lines.clear();
}
