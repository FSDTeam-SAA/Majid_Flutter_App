/// A single inventory / stock item (a device or other tracked product).
class InventoryItem {
  final String id;
  final String itemName;
  final String? sku;
  final String? brand;
  final String? color;
  final String? storage;
  final String? modelNumber;
  final String imeiNumber;
  final String currentState;
  final String status;
  final int quantity;
  final num? purchasePrice;
  final num? expectedPrice;
  final int? minStockLevel;
  final String? groupKey;
  final String? productDetails;
  final String? categoryId;
  final String? categoryName;
  final String? imageUrl;

  const InventoryItem({
    required this.id,
    required this.itemName,
    this.sku,
    this.brand,
    this.color,
    this.storage,
    this.modelNumber,
    required this.imeiNumber,
    required this.currentState,
    this.status = 'inventory',
    this.quantity = 0,
    this.purchasePrice,
    this.expectedPrice,
    this.minStockLevel,
    this.groupKey,
    this.productDetails,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
  });

  /// Preferred display price: expected (sale) price, falling back to
  /// purchase price, matching the price shown across the stock UI.
  double get price => (expectedPrice ?? purchasePrice ?? 0).toDouble();
}
