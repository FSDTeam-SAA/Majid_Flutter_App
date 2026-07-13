import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../stock/domain/repositories/inventory_repository.dart';
import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';

ScoreMetric _metricFromJson(dynamic json) {
  if (json is! Map) return ScoreMetric.zero;
  return ScoreMetric(score: (json['score'] as num?)?.toInt() ?? 0);
}

DashboardStats _statsFromJson(Map<String, dynamic> json) {
  final health = json['businessHealthScore'] as Map? ?? {};
  final metrics = json['metrics'] as Map? ?? {};
  final insights = (json['insights'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];

  return DashboardStats(
    healthScoreOverall: (health['overall'] as num?)?.toInt() ?? 0,
    healthScoreRating: health['rating']?.toString() ?? '',
    healthScoreMessage: health['message']?.toString() ?? '',
    metrics: DashboardMetrics(
      salesGrowth: _metricFromJson(metrics['salesGrowth']),
      profitMargin: _metricFromJson(metrics['profitMargin']),
      stockManagement: _metricFromJson(metrics['stockManagement']),
      customerSatisfaction: _metricFromJson(metrics['customerSatisfaction']),
      outstandingPayments: _metricFromJson(metrics['outstandingPayments']),
    ),
    insights: insights,
    totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0,
    totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
  );
}

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient _api;
  final InventoryRepository _inventoryRepository;

  DashboardRepositoryImpl(this._api, this._inventoryRepository);

  @override
  Future<DashboardStats> getStats({required String filter, String? shopkeeperId}) async {
    final query = shopkeeperId != null && shopkeeperId.isNotEmpty
        ? '?filter=$filter&shopkeeperId=$shopkeeperId'
        : '?filter=$filter';
    final res = await _api.get('${DashboardEndpoints.stats}$query');
    return _statsFromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<BusinessHealthLegacyStats> getLegacyBusinessHealthStats() async {
    final repairFuture = _api.get(RepairRequestEndpoints.myHistory);
    final inventoryFuture = _inventoryRepository.getMyInventory();

    final repairRes = await repairFuture;
    final inventoryItems = await inventoryFuture;

    final repairData = repairRes.data;
    final rawTotal =
        repairData['meta']?['total'] ??
        (repairData['data'] is List ? repairData['data'].length : 0);

    return BusinessHealthLegacyStats(
      totalRepairs: (rawTotal as num?)?.toInt() ?? 0,
      totalInventoryItems: inventoryItems.length,
    );
  }
}
