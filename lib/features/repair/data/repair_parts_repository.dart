import '../../../core/network/api_service/api_client.dart';
import '../../../features/stock/data/repositories/inventory_repository_impl.dart';
import '../../../features/stock/domain/entities/inventory_item.dart';

const repairPartMarker = '[imoscan:repair-part]';

bool isRepairPart(InventoryItem item) {
  if ((item.productDetails ?? '').contains(repairPartMarker)) return true;
  final category = (item.categoryName ?? '').toLowerCase();
  if (RegExp(r'\b(parts?|spares?|components?)\b').hasMatch(category)) {
    return true;
  }
  return RegExp(
    r'\b(replacement|screen|battery|speaker|flex|connector|digitizer)\b|charging port',
    caseSensitive: false,
  ).hasMatch(item.itemName);
}

class RepairPartsRepository {
  RepairPartsRepository(ApiClient api)
    : _inventory = InventoryRepositoryImpl(api);
  final InventoryRepositoryImpl _inventory;
  Future<List<String>> names() async {
    final items = await _inventory.getMyInventory();
    return items
        .where(isRepairPart)
        .map((item) => item.itemName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  Future<String> create(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const FormatException('Part name is required');
    // Inventory accepts product codes as well as handset IMEIs. A generated
    // part code keeps this catalog entry separate from handset identifiers.
    final code = 'PART-${DateTime.now().microsecondsSinceEpoch}';
    final item = await _inventory.createItem(
      data: {
        'itemName': trimmed,
        'imeiNumber': code,
        'sku': code,
        'productDetails': repairPartMarker,
        'quantity': 0,
        'minStockLevel': 0,
        'currentState': 'new',
        'status': 'inventory',
        'type': 'inventory',
      },
    );
    if (item.id.isEmpty) {
      throw const FormatException('Part save was not confirmed');
    }
    return item.itemName;
  }
}
