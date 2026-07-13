import '../entities/csv_import_summary.dart';
import '../entities/inventory_item.dart';

abstract class InventoryRepository {
  /// Fetches all inventory items belonging to [shopkeeperId].
  Future<List<InventoryItem>> getByShopkeeperId(String shopkeeperId);

  /// Fetches the current user's own inventory (used when the shopkeeper id
  /// couldn't be resolved from the profile/auth state).
  Future<List<InventoryItem>> getMyInventory();

  /// Creates a single inventory item. [imagePath], when provided, is
  /// uploaded as a multipart image field alongside [data].
  Future<InventoryItem> createItem({
    required Map<String, dynamic> data,
    String? imagePath,
  });

  /// Updates the inventory item identified by [id]. [imagePath], when
  /// provided, is uploaded as a multipart image field alongside [data].
  Future<InventoryItem> updateItem({
    required String id,
    required Map<String, dynamic> data,
    String? imagePath,
  });

  Future<void> deleteItem(String id);

  /// Bulk-creates inventory items from scanned barcodes.
  Future<void> createFromBarcodeBulk({
    required String currentState,
    required List<Map<String, dynamic>> items,
  });

  /// Imports inventory items from a CSV/XLS/XLSX file, either from a file
  /// system [filePath] or raw [fileBytes] (web / no-path pickers).
  Future<CsvImportSummary> importCsv({
    String? filePath,
    List<int>? fileBytes,
    required String filename,
  });
}
