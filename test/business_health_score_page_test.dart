import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:majid_flutter_app/features/profile/domain/entities/dashboard_stats.dart';
import 'package:majid_flutter_app/features/profile/presentation/controller/profile_controller.dart';
import 'package:majid_flutter_app/features/profile/presentation/pages/business_health_score_page.dart';

void main() {
  // Guards the layout as a whole: a single bad constraint in here renders the
  // page as a blank scroll area rather than an error, so it is easy to ship.
  testWidgets('health page builds with stats', (tester) async {
    final ctrl = ProfileController();
    Get.put<ProfileController>(ctrl);
    ctrl.dashboardStats.value = const DashboardStats(
      healthScoreOverall: 64,
      healthScoreRating: 'Fair',
      healthScoreMessage: 'Your business has room for improvement.',
      metrics: DashboardMetrics(
        salesGrowth: ScoreMetric(score: 83),
        profitMargin: ScoreMetric(score: 0),
        stockManagement: ScoreMetric(score: 83),
        customerSatisfaction: ScoreMetric(score: 80),
        outstandingPayments: ScoreMetric(score: 100),
      ),
      insights: ['Sales are up 12% on last month.'],
      totalSales: 1467,
      totalOrders: 2,
    );

    await tester.pumpWidget(const MaterialApp(home: BusinessHealthScorePage()));
    await tester.pump(const Duration(milliseconds: 100));
    // Let the gauge and bar animations settle before reading their values.
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Score Breakdown'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);
    expect(find.text('HEALTH SCORE'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
  });
}
