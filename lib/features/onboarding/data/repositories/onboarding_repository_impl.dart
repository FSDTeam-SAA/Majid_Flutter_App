import 'package:dio/dio.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../scan/domain/entities/scan_service_option.dart';
import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final ApiClient _api;

  OnboardingRepositoryImpl(this._api);

  @override
  Future<List<ScanDropdownOption>> getFreeServices() async {
    final res = await _api.get(ImeiEndpoints.services);
    final data = res.data['data'];
    if (data is! List) return [];

    final options = <ScanDropdownOption>[];
    for (final group in data) {
      if (group is! Map) continue;
      final groupServices = group['services'];
      if (groupServices is! List) continue;
      for (final service in groupServices) {
        if (service is! Map) continue;
        if (service['isFree'] != true) continue;
        final id = (service['serviceId'] as num?)?.toInt();
        final ids = service['serviceIds'];
        final fallbackId = ids is List && ids.isNotEmpty
            ? (ids.first as num?)?.toInt()
            : null;
        final serviceId = id ?? fallbackId;
        if (serviceId == null || serviceId <= 0) continue;
        options.add(
          ScanDropdownOption(
            service['name']?.toString() ?? 'Free Check',
            'Free',
            serviceId: serviceId,
          ),
        );
      }
    }
    return options;
  }

  @override
  Future<Map<String, dynamic>> checkImeiFree({
    required String imei,
    required int serviceId,
  }) async {
    final Response res;
    try {
      res = await _api.post(
        ImeiEndpoints.checkV2,
        data: {'imei': imei, 'serviceId': serviceId},
      );
    } on DioException catch (e) {
      throw OnboardingScanException(
        e.response?.data?['message']?.toString() ??
            'Scan failed. Please try again.',
      );
    }

    final data = res.data['data'];
    if (data is! List || data.isEmpty) {
      throw const OnboardingScanException('Scan failed. Please try again.');
    }
    final first = data.first;
    if (first is! Map || first['ok'] != true) {
      throw OnboardingScanException(
        first is Map
            ? first['message']?.toString() ?? 'Device data not found.'
            : 'Device data not found.',
      );
    }
    return Map<String, dynamic>.from(first);
  }
}
