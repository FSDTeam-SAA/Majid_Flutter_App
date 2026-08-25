import '../entities/cash_management_data.dart';

abstract class CashManagementRepository {
  Future<CashManagementData?> getCashManagement(String shopkeeperId);
  Future<CashManagementStats?> getStats(String shopkeeperId);
  Future<CashManagementData> createOrUpdateCashManagement({
    required String shopkeeperId,
    required double startingDayCash,
    required double banked,
    required double cashInDrawer,
  });
}
