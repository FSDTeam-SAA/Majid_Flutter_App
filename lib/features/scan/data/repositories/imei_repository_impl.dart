import 'package:dio/dio.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/scan_item.dart';
import '../../domain/entities/scan_service_option.dart';
import '../../domain/repositories/imei_repository.dart';
import 'scan_item_mapper.dart';

class ImeiRepositoryImpl implements ImeiRepository {
  final ApiClient _api;

  ImeiRepositoryImpl(this._api);

  @override
  Future<List<ScanDropdownOption>> getServices() async {
    final res = await _api.get(ImeiEndpoints.services);
    final data = res.data['data'];
    if (data is! List) {
      throw const ImeiScanException('Invalid services response');
    }

    final groups = List<Map<String, dynamic>>.from(
      data.whereType<Map>().map((m) => Map<String, dynamic>.from(m)),
    );

    // Reorder categories: put "fevourite" first, matching website behavior
    groups.sort((a, b) {
      final aCat = (a['category']?.toString() ?? '').toLowerCase();
      final bCat = (b['category']?.toString() ?? '').toLowerCase();
      final aIsFav = aCat.contains('fevourite') || aCat.contains('favourite');
      final bIsFav = bCat.contains('fevourite') || bCat.contains('favourite');
      if (aIsFav && !bIsFav) return -1;
      if (!aIsFav && bIsFav) return 1;
      return aCat.compareTo(bCat);
    });

    final services = <ScanDropdownOption>[];
    for (final group in groups) {
      final groupServices = group['services'];
      if (groupServices is! List) continue;
      for (final service in groupServices) {
        if (service is! Map) continue;
        final id = (service['serviceId'] as num?)?.toInt();
        final ids = service['serviceIds'];
        final fallbackId = ids is List && ids.isNotEmpty
            ? (ids.first as num?)?.toInt()
            : null;
        final serviceId = id ?? fallbackId;
        if (serviceId == null || serviceId <= 0) continue;
        final isFree = service['isFree'] == true;
        services.add(
          ScanDropdownOption(
            service['name']?.toString() ?? 'IMEI Check',
            isFree ? 'Free' : service['priceLabel']?.toString() ?? 'Premium',
            serviceId: serviceId,
          ),
        );
      }
    }
    return services;
  }

  @override
  Future<Map<String, dynamic>> checkImei({
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
      throw ImeiScanException(e.response?.data?['message']?.toString() ?? '');
    }

    final data = res.data['data'];
    if (data is! List || data.isEmpty) {
      throw const ImeiScanException('');
    }
    final first = data.first;
    if (first is! Map || first['ok'] != true) {
      throw ImeiScanException(
        first is Map ? (first['message']?.toString() ?? '') : '',
      );
    }
    return Map<String, dynamic>.from(first);
  }

  @override
  Future<ScanHistoryResult> getHistoryResult({int? page, int? limit}) async {
    final params = <String, dynamic>{};
    if (page != null && page > 0) params['page'] = page;
    if (limit != null && limit > 0) params['limit'] = limit;

    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final url = queryString.isNotEmpty
        ? '${ImeiEndpoints.history}?$queryString'
        : ImeiEndpoints.history;

    final res = await _api.get(url);
    final data = res.data['data'];
    if (data is! List) {
      throw const ImeiScanException('Invalid scan history response');
    }

    final items = data
        .whereType<Map>()
        .map((item) => scanItemFromJson(Map<String, dynamic>.from(item)))
        .toList();

    final meta = res.data['meta'];
    final total = meta is Map ? (meta['total'] as num?)?.toInt() ?? items.length : items.length;
    final resPage = meta is Map ? (meta['page'] as num?)?.toInt() ?? 1 : 1;
    final totalPage = meta is Map ? (meta['totalPage'] as num?)?.toInt() ?? 1 : 1;

    return ScanHistoryResult(
      items: items,
      total: total,
      page: resPage,
      totalPage: totalPage,
    );
  }

  @override
  Future<List<ScanItem>> getHistory({int? limit}) async {
    final result = await getHistoryResult(limit: limit);
    return result.items;
  }

  @override
  Future<Map<String, dynamic>> getHistoryReport(String reportId) async {
    final Response res;
    try {
      res = await _api.get(ImeiEndpoints.historyReport(reportId));
    } on DioException catch (e) {
      throw ImeiScanException(
        e.response?.data?['message']?.toString() ??
            'Failed to load saved device report',
      );
    }

    final data = res.data['data'];
    if (data is! Map) {
      throw const ImeiScanException('Invalid saved device report');
    }
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<List<String>> extractImeiFromImage(
    String imagePath, {
    required String fileName,
  }) async {
    final Response res;
    try {
      final payload = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: fileName),
      });
      res = await _api.post(OcrEndpoints.extractImei, data: payload);
    } on DioException catch (e) {
      throw ImeiScanException(
        e.response?.data?['message']?.toString() ??
            'Failed to extract IMEI from image.',
      );
    }

    final responseData = res.data is Map ? res.data['data'] : null;
    return _extractImeis(responseData);
  }

  @override
  Future<Map<String, dynamic>> searchBarcode(String code) async {
    final Response res;
    try {
      res = await _api.get(BarcodeEndpoints.search(code));
    } on DioException catch (e) {
      throw ImeiScanException(
        e.response?.data?['message']?.toString() ?? 'Barcode lookup failed',
      );
    }

    final data = res.data is Map ? res.data['data'] : null;
    if (data is! Map) {
      throw const ImeiScanException('Barcode lookup failed');
    }
    return Map<String, dynamic>.from(data);
  }

  List<String> _extractImeis(dynamic responseData) {
    final imeis = <String>{};

    void addCandidate(dynamic value) {
      if (value == null) return;
      final normalized = _normalizeImei(value.toString());
      if (_isValidImei(normalized)) {
        imeis.add(normalized);
      }
    }

    if (responseData is Map) {
      // Check every plausible field name — future-proofing for whenever the
      // backend OCR prompt learns to detect Serial Numbers separately from
      // IMEIs, without needing another app update. A Set dedupes, so
      // checking overlapping names here is harmless.
      for (final key in ['imeiNumbers', 'imeis', 'serialNumbers', 'serials']) {
        final list = responseData[key];
        if (list is List) {
          for (final item in list) {
            addCandidate(item);
          }
        }
      }

      addCandidate(responseData['imei']);
      addCandidate(responseData['imeiNumber']);
      addCandidate(responseData['serial']);
      addCandidate(responseData['serialNumber']);

      final rawText = responseData['rawText'];
      if (rawText is String) {
        for (final match in RegExp(r'\d{15}').allMatches(rawText)) {
          addCandidate(match.group(0));
        }
        // Serial Numbers are alphanumeric, not 15 digits — the backend OCR
        // prompt is currently IMEI-only, but this catches a Serial if one
        // ever shows up in the raw recognized text.
        for (final match in RegExp(
          r'\b[A-Za-z0-9]{8,14}\b',
        ).allMatches(rawText)) {
          final candidate = match.group(0)!;
          if (RegExp(r'[A-Za-z]').hasMatch(candidate)) {
            addCandidate(candidate);
          }
        }
      }
    } else if (responseData is List) {
      for (final item in responseData) {
        addCandidate(item);
      }
    }

    return imeis.toList();
  }

  /// Strips separators but keeps letters — Serial Numbers are alphanumeric,
  /// unlike IMEIs which are 15 digits.
  String _normalizeImei(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  /// A 15-digit IMEI or an alphanumeric Serial Number — mirrors the
  /// backend's own `isValidImei` check.
  bool _isValidImei(String value) =>
      RegExp(r'^\d{15}$').hasMatch(value) ||
      RegExp(r'^[A-Za-z0-9]{4,}$').hasMatch(value);
}
