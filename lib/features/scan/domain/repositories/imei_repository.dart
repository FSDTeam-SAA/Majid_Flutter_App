import '../entities/scan_item.dart';
import '../entities/scan_service_option.dart';

/// Thrown by [ImeiRepository] methods when a request completes but the
/// response does not contain usable data. The [message] mirrors the text
/// previously shown directly in the UI's SnackBars.
class ImeiScanException implements Exception {
  final String message;

  const ImeiScanException(this.message);

  @override
  String toString() => message;
}

/// Covers the full set of IMEI-scan related calls used by the `scan`
/// feature: browsing/selecting a verification service, running an IMEI
/// check, viewing scan history, extracting an IMEI from a photo (OCR), and
/// looking up a product by barcode.
abstract class ImeiRepository {
  /// Fetches every IMEI-check service (free and paid). Callers that only
  /// want free services should filter the result themselves.
  Future<List<ScanDropdownOption>> getServices();

  /// Submits an IMEI check and returns the parsed check-result map (the
  /// same shape expected by `DeviceReportPage`), e.g.
  /// `{ok: true, data: {...}}`.
  ///
  /// Throws an [ImeiScanException] when the response does not contain a
  /// usable result (e.g. empty result set or `ok != true`).
  Future<Map<String, dynamic>> checkImei({
    required String imei,
    required int serviceId,
  });

  /// Fetches recent scan history, most-recent semantics left to the caller
  /// (server ordering is not guaranteed). [limit] caps the number of
  /// records returned by the API, when supported.
  Future<List<ScanItem>> getHistory({int? limit});

  /// Uploads [imagePath] to the OCR service and returns every IMEI number
  /// it could find in the image (deduplicated, order preserved).
  ///
  /// Throws an [ImeiScanException] when the request fails.
  Future<List<String>> extractImeiFromImage(String imagePath, {
    required String fileName,
  });

  /// Looks up a scanned barcode and returns the raw product map (name,
  /// brand, category, description, image, ...).
  ///
  /// Throws an [ImeiScanException] when the request fails or the response
  /// shape is invalid.
  Future<Map<String, dynamic>> searchBarcode(String code);
}
