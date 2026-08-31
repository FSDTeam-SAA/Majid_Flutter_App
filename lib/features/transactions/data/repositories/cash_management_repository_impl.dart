import 'package:dio/dio.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/cash_management_data.dart';
import '../../domain/repositories/cash_management_repository.dart';

class CashManagementRepositoryImpl implements CashManagementRepository {
  final ApiClient _api;

  CashManagementRepositoryImpl(this._api);

  @override
  Future<CashManagementData?> getCashManagement(String shopkeeperId) async {
    try {
      final response = await _api.dio.get(
        CashManagementEndpoints.byShopkeeper(shopkeeperId),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return CashManagementData.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<CashManagementStats?> getStats(String shopkeeperId) async {
    try {
      final response = await _api.dio.get(
        CashManagementEndpoints.stats(shopkeeperId),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return CashManagementStats.fromJson(
          data['data'] as Map<String, dynamic>,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CashManagementData> createOrUpdateCashManagement({
    required String shopkeeperId,
    required double startingDayCash,
    required double banked,
    required double cashInDrawer,
  }) async {
    final response = await _api.dio.post(
      CashManagementEndpoints.createOrUpdate,
      data: {
        'shopkeeperId': shopkeeperId,
        'startingDayCash': startingDayCash,
        'banked': banked,
        'cashInDrawer': cashInDrawer,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      return CashManagementData.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception('Invalid server response');
  }
}
