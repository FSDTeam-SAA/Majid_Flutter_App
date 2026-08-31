class CashManagementData {
  final String? id;
  final String shopkeeperId;
  final double startingDayCash;
  final double banked;
  final double cashInDrawer;
  final int cashManagementScore;
  final String aiInsight;
  final DateTime? date;

  const CashManagementData({
    this.id,
    required this.shopkeeperId,
    required this.startingDayCash,
    required this.banked,
    required this.cashInDrawer,
    required this.cashManagementScore,
    required this.aiInsight,
    this.date,
  });

  double get totalCash => banked + cashInDrawer;
  double get variance => (banked + cashInDrawer - startingDayCash).abs();
  double get remainingToBank => (cashInDrawer - startingDayCash) > 0
      ? (cashInDrawer - startingDayCash)
      : cashInDrawer;

  factory CashManagementData.fromJson(Map<String, dynamic> json) {
    return CashManagementData(
      id: json['_id']?.toString(),
      shopkeeperId: json['shopkeeperId'] is Map
          ? json['shopkeeperId']['_id']?.toString() ?? ''
          : json['shopkeeperId']?.toString() ?? '',
      startingDayCash: (json['startingDayCash'] as num?)?.toDouble() ?? 0.0,
      banked: (json['banked'] as num?)?.toDouble() ?? 0.0,
      cashInDrawer: (json['cashInDrawer'] as num?)?.toDouble() ?? 0.0,
      cashManagementScore: (json['cashManagementScore'] as num?)?.toInt() ?? 0,
      aiInsight: json['aiInsight']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopkeeperId': shopkeeperId,
      'startingDayCash': startingDayCash,
      'banked': banked,
      'cashInDrawer': cashInDrawer,
    };
  }

  CashManagementData copyWith({
    String? id,
    String? shopkeeperId,
    double? startingDayCash,
    double? banked,
    double? cashInDrawer,
    int? cashManagementScore,
    String? aiInsight,
    DateTime? date,
  }) {
    return CashManagementData(
      id: id ?? this.id,
      shopkeeperId: shopkeeperId ?? this.shopkeeperId,
      startingDayCash: startingDayCash ?? this.startingDayCash,
      banked: banked ?? this.banked,
      cashInDrawer: cashInDrawer ?? this.cashInDrawer,
      cashManagementScore: cashManagementScore ?? this.cashManagementScore,
      aiInsight: aiInsight ?? this.aiInsight,
      date: date ?? this.date,
    );
  }
}

class CashManagementStats {
  final int averageScore;
  final int totalRecords;
  final String recentTrend;

  const CashManagementStats({
    required this.averageScore,
    required this.totalRecords,
    required this.recentTrend,
  });

  factory CashManagementStats.fromJson(Map<String, dynamic> json) {
    return CashManagementStats(
      averageScore: (json['averageScore'] as num?)?.toInt() ?? 0,
      totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
      recentTrend: json['recentTrend']?.toString() ?? 'Stable',
    );
  }
}
