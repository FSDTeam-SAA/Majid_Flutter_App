import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import 'home_data.dart';

class HomeController extends GetxController {
  late final ApiClient _api;

  final isLoading = true.obs;
  final errorMessage = ''.obs;

  // Profile
  final userName = ''.obs;
  final userImage = ''.obs;
  final userId = ''.obs;

  // Stats
  final totalInventoryItems = 0.obs;
  final totalSoldProducts = 0.obs;
  final totalRepairRequests = 0.obs;
  final totalCategories = 0.obs;

  // Sold inventory items (top selling)
  final soldProducts = <Map<String, dynamic>>[].obs;

  // Inventory items
  final inventoryItems = <Map<String, dynamic>>[].obs;

  // Repair requests
  final repairRequests = <Map<String, dynamic>>[].obs;

  // Categories
  final categories = <Map<String, dynamic>>[].obs;

  // Invoices
  final invoices = <Map<String, dynamic>>[].obs;

  // Dashboard stats (for health summary section)
  final dashboardStats = Rx<Map<String, dynamic>?>(null);

  // Cash management
  final cashManagement = Rx<Map<String, dynamic>?>(null);
  final isSubmittingCash = false.obs;

  @override
  void onInit() {
    super.onInit();
    _api = ApiClient(baseUrl);
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _fetchProfile();
      await Future.wait([
        _fetchInventory(),
        _fetchSoldItems(),
        _fetchRepairRequests(),
        _fetchCategories(),
        _fetchInvoices(),
      ]);
      // fetch dashboard after profile so userId is available
      await _fetchDashboardStats();
      await _fetchCashManagement();
    } catch (e) {
      debugPrint('HomeController error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await _api.get(UserEndpoints.myProfile);
      final data = res.data['data'];
      if (data != null) {
        final first = data['firstName'] ?? '';
        final last = data['lastName'] ?? '';
        userName.value = '$first $last'.trim();
        userId.value = data['_id']?.toString() ?? '';
        final img = data['image'];
        if (img is Map && img['url'] != null) {
          userImage.value = img['url'];
        }
      }
    } on DioException catch (e) {
      debugPrint('Profile fetch error: $e');
    }
  }

  Future<void> _fetchInventory() async {
    try {
      final res = await _api.get(InventoryEndpoints.myInventory);
      final data = res.data['data'];
      if (data is List) {
        inventoryItems.value = List<Map<String, dynamic>>.from(data);
        totalInventoryItems.value = data.length;
      }
    } on DioException catch (e) {
      debugPrint('Inventory fetch error: $e');
    }
  }

  Future<void> _fetchSoldItems() async {
    try {
      final res = await _api.get(InventoryEndpoints.soldItems);
      final data = res.data['data'];
      if (data is List) {
        final items = List<Map<String, dynamic>>.from(data);
        soldProducts.value = items;
        totalSoldProducts.value = items.length;
      }
    } on DioException catch (e) {
      debugPrint('Sold items fetch error: $e');
    }
  }

  Future<void> _fetchRepairRequests() async {
    try {
      final res = await _api.get(RepairRequestEndpoints.myHistory);
      final data = res.data['data'];
      if (data is List) {
        repairRequests.value = List<Map<String, dynamic>>.from(data);
        totalRepairRequests.value = res.data['meta']?['total'] ?? data.length;
      }
    } on DioException catch (e) {
      debugPrint('Repair requests fetch error: $e');
    }
  }

  Future<void> _fetchCategories() async {
    final id = userId.value.trim();
    if (id.isEmpty) {
      categories.clear();
      totalCategories.value = 0;
      return;
    }

    try {
      final res = await _api.get(
        '${CategoryEndpoints.withCount}?shopkeeperId=$id',
      );
      final data = res.data['data'];
      if (data is List) {
        categories.value = List<Map<String, dynamic>>.from(data);
        totalCategories.value = data.length;
      }
    } on DioException catch (e) {
      debugPrint('Categories fetch error: $e');
    }
  }

  Future<void> _fetchDashboardStats({String filter = 'monthly'}) async {
    final id = userId.value.trim();
    if (id.isEmpty) return;
    try {
      final res = await _api.get('${DashboardEndpoints.stats}?filter=$filter&shopkeeperId=$id');
      final data = res.data['data'];
      if (data is Map) {
        dashboardStats.value = Map<String, dynamic>.from(data);
      }
    } on DioException catch (e) {
      debugPrint('Dashboard stats fetch error: $e');
    }
  }

  Future<void> fetchDashboardForFilter(String filter) =>
      _fetchDashboardStats(filter: filter);

  Future<void> _fetchCashManagement() async {
    final id = userId.value.trim();
    if (id.isEmpty) return;
    try {
      final res = await _api.get(CashManagementEndpoints.byShopkeeper(id));
      final data = res.data['data'];
      if (data is Map) {
        cashManagement.value = Map<String, dynamic>.from(data);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        debugPrint('Cash management fetch error: $e');
      }
    }
  }

  Future<bool> submitStartingDayCash(double startingDayCash) async {
    final id = userId.value.trim();
    if (id.isEmpty) return false;
    isSubmittingCash.value = true;
    try {
      final res = await _api.post(
        CashManagementEndpoints.createOrUpdate,
        data: {
          'shopkeeperId': id,
          'startingDayCash': startingDayCash,
        },
      );
      final data = res.data['data'];
      if (data is Map) {
        cashManagement.value = Map<String, dynamic>.from(data);
      }
      return true;
    } on DioException catch (e) {
      debugPrint('Cash management submit error: $e');
      return false;
    } finally {
      isSubmittingCash.value = false;
    }
  }

  Future<void> _fetchInvoices() async {
    final shopkeeperId = userId.value.trim();
    if (shopkeeperId.isEmpty) {
      invoices.clear();
      return;
    }

    try {
      final res = await _api.get(InvoiceEndpoints.byShopkeeper(shopkeeperId));
      final data = res.data['data'];
      if (data is List) {
        invoices.value = List<Map<String, dynamic>>.from(data);
      } else {
        invoices.clear();
      }
    } on DioException catch (e) {
      debugPrint('Invoices fetch error: $e');
    }
  }

  double get totalInventoryValue => inventoryItems.fold(0.0, (sum, item) {
        final price = (item['sellingPrice'] as num?)?.toDouble() ??
            (item['price'] as num?)?.toDouble() ?? 0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        return sum + price * qty;
      });

  HomeStatsSnapshot statsForPeriod(HomePeriod period) {
    return HomeStatsSnapshot(
      totalItems: _countRecordsForPeriod(inventoryItems, period),
      soldProducts: _countRecordsForPeriod(
        soldProducts,
        period,
        dateKeys: const ['soldAt', 'updatedAt', 'createdAt'],
      ),
      repairRequests: _countRecordsForPeriod(repairRequests, period),
      categories: _countRecordsForPeriod(categories, period),
    );
  }

  SalesTrendData salesTrendForPeriod(HomePeriod period) {
    final currentBuckets = _bucketDates(period, previous: false);
    final previousBuckets = _bucketDates(period, previous: true);
    final currentValues = List<double>.filled(currentBuckets.labels.length, 0);
    final previousValues = List<double>.filled(previousBuckets.labels.length, 0);

    for (final invoice in invoices) {
      final date = _resolveDate(invoice, const ['createdAt', 'updatedAt']);
      if (date == null) continue;

      final totalAmount = _toDouble(invoice['totalAmount']);

      final currentIndex = currentBuckets.indexFor(date);
      if (currentIndex != null) {
        currentValues[currentIndex] += totalAmount;
      }

      final previousIndex = previousBuckets.indexFor(date);
      if (previousIndex != null) {
        previousValues[previousIndex] += totalAmount;
      }
    }

    return SalesTrendData(
      periodLabel: period.label,
      currentLegend: period.currentLegend,
      previousLegend: period.previousLegend,
      currentValues: currentValues,
      previousValues: previousValues,
      axisLabels: currentBuckets.labels,
    );
  }

  int _countRecordsForPeriod(
    List<Map<String, dynamic>> records,
    HomePeriod period, {
    List<String> dateKeys = const ['createdAt'],
  }) {
    return records.where((record) {
      final date = _resolveDate(record, dateKeys);
      return date != null && _isInPeriod(date, period);
    }).length;
  }

  bool _isInPeriod(DateTime date, HomePeriod period) {
    final now = DateTime.now();
    final current = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case HomePeriod.daily:
        return current == today;
      case HomePeriod.weekly:
        final start = _startOfWeek(today);
        final end = start.add(const Duration(days: 7));
        return !current.isBefore(start) && current.isBefore(end);
      case HomePeriod.monthly:
        return date.year == now.year && date.month == now.month;
      case HomePeriod.yearly:
        return date.year == now.year;
    }
  }

  DateTime? _resolveDate(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      final parsed = DateTime.tryParse(value.toString());
      if (parsed != null) {
        return parsed.toLocal();
      }
    }
    return null;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _startOfWeek(DateTime value) {
    final weekday = value.weekday;
    return DateTime(value.year, value.month, value.day)
        .subtract(Duration(days: weekday - 1));
  }

  _TrendBuckets _bucketDates(HomePeriod period, {required bool previous}) {
    final now = DateTime.now();
    switch (period) {
      case HomePeriod.daily:
        final base = DateTime(now.year, now.month, now.day).subtract(
          Duration(days: previous ? 1 : 0),
        );
        return _TrendBuckets(
          labels: const ['12A', '4A', '8A', '12P', '4P', '8P'],
          indexFor: (date) {
            final day = DateTime(date.year, date.month, date.day);
            if (day != base) return null;
            return (date.hour ~/ 4).clamp(0, 5);
          },
        );
      case HomePeriod.weekly:
        final currentWeekStart = _startOfWeek(
          DateTime(now.year, now.month, now.day),
        );
        final base = currentWeekStart.subtract(
          Duration(days: previous ? 7 : 0),
        );
        return _TrendBuckets(
          labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
          indexFor: (date) {
            final day = DateTime(date.year, date.month, date.day);
            final diff = day.difference(base).inDays;
            return diff >= 0 && diff < 7 ? diff : null;
          },
        );
      case HomePeriod.monthly:
        final monthDate = DateTime(
          now.year,
          now.month - (previous ? 1 : 0),
          1,
        );
        return _TrendBuckets(
          labels: const ['W1', 'W2', 'W3', 'W4', 'W5'],
          indexFor: (date) {
            if (date.year != monthDate.year || date.month != monthDate.month) {
              return null;
            }
            return ((date.day - 1) ~/ 7).clamp(0, 4);
          },
        );
      case HomePeriod.yearly:
        final year = now.year - (previous ? 1 : 0);
        return _TrendBuckets(
          labels: const [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ],
          indexFor: (date) => date.year == year ? date.month - 1 : null,
        );
    }
  }
}

class _TrendBuckets {
  final List<String> labels;
  final int? Function(DateTime date) indexFor;

  const _TrendBuckets({
    required this.labels,
    required this.indexFor,
  });
}
