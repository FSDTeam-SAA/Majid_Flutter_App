/// A single scored metric (0-100) within the business health breakdown.
class ScoreMetric {
  final int score;

  const ScoreMetric({required this.score});

  static const zero = ScoreMetric(score: 0);
}

/// The five metrics that make up the business health score breakdown shown
/// on [BusinessHealthScorePage].
class DashboardMetrics {
  final ScoreMetric salesGrowth;
  final ScoreMetric profitMargin;
  final ScoreMetric stockManagement;
  final ScoreMetric customerSatisfaction;
  final ScoreMetric outstandingPayments;

  const DashboardMetrics({
    required this.salesGrowth,
    required this.profitMargin,
    required this.stockManagement,
    required this.customerSatisfaction,
    required this.outstandingPayments,
  });

  static const zero = DashboardMetrics(
    salesGrowth: ScoreMetric.zero,
    profitMargin: ScoreMetric.zero,
    stockManagement: ScoreMetric.zero,
    customerSatisfaction: ScoreMetric.zero,
    outstandingPayments: ScoreMetric.zero,
  );
}

/// Aggregated dashboard/business-health data for the current shopkeeper,
/// as returned by the dashboard stats endpoint.
class DashboardStats {
  final int healthScoreOverall;
  final String healthScoreRating;
  final String healthScoreMessage;
  final DashboardMetrics metrics;
  final List<String> insights;
  final double totalSales;
  final int totalOrders;

  const DashboardStats({
    required this.healthScoreOverall,
    required this.healthScoreRating,
    required this.healthScoreMessage,
    required this.metrics,
    required this.insights,
    required this.totalSales,
    required this.totalOrders,
  });
}

/// Legacy fallback business-health counters, derived from the repair
/// history and inventory endpoints directly (kept alongside [DashboardStats]
/// for callers that haven't migrated to the richer dashboard stats yet).
class BusinessHealthLegacyStats {
  final int totalRepairs;
  final int totalInventoryItems;

  const BusinessHealthLegacyStats({
    required this.totalRepairs,
    required this.totalInventoryItems,
  });
}
