import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  /// Fetches the dashboard/business-health stats for [shopkeeperId] (or the
  /// caller's own shop when omitted), bucketed by [filter] (e.g. `monthly`).
  Future<DashboardStats> getStats({
    required String filter,
    String? shopkeeperId,
  });

  /// Fetches the legacy business-health counters (repair request count +
  /// inventory item count), used as a fallback before [DashboardStats] was
  /// introduced. Inventory count is sourced from the stock feature's
  /// [InventoryRepository.getMyInventory] rather than re-implemented here.
  Future<BusinessHealthLegacyStats> getLegacyBusinessHealthStats();
}
