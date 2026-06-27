enum HomePeriod { daily, weekly, monthly, yearly }

const periods = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

extension HomePeriodX on HomePeriod {
  String get label => switch (this) {
    HomePeriod.daily => 'Daily',
    HomePeriod.weekly => 'Weekly',
    HomePeriod.monthly => 'Monthly',
    HomePeriod.yearly => 'Yearly',
  };

  String get currentLegend => switch (this) {
    HomePeriod.daily => 'Today',
    HomePeriod.weekly => 'This Week',
    HomePeriod.monthly => 'This Month',
    HomePeriod.yearly => 'This Year',
  };

  String get previousLegend => switch (this) {
    HomePeriod.daily => 'Yesterday',
    HomePeriod.weekly => 'Last Week',
    HomePeriod.monthly => 'Last Month',
    HomePeriod.yearly => 'Last Year',
  };
}

HomePeriod homePeriodFromIndex(int index) {
  return switch (index) {
    0 => HomePeriod.daily,
    1 => HomePeriod.weekly,
    2 => HomePeriod.monthly,
    _ => HomePeriod.yearly,
  };
}

class HomeStatsSnapshot {
  final int totalItems;
  final int soldProducts;
  final int repairRequests;
  final int categories;

  const HomeStatsSnapshot({
    required this.totalItems,
    required this.soldProducts,
    required this.repairRequests,
    required this.categories,
  });
}

class SalesTrendData {
  final String periodLabel;
  final String currentLegend;
  final String previousLegend;
  final List<double> currentValues;
  final List<double> previousValues;
  final List<String> axisLabels;

  const SalesTrendData({
    required this.periodLabel,
    required this.currentLegend,
    required this.previousLegend,
    required this.currentValues,
    required this.previousValues,
    required this.axisLabels,
  });
}
