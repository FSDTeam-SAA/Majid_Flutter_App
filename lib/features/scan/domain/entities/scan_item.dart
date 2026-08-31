/// A single IMEI scan (or scan-history) entry, whether it came back from the
/// API's `/imei/history` endpoint or was produced locally right after a scan.
class ScanItem {
  final String name;
  final String imei;
  final String status;
  final int? serviceId;
  final DateTime? createdAt;

  /// The raw check result payload for this scan, when available (e.g. the
  /// `data` object from `ImeiEndpoints.checkV2`). Used to open
  /// `DeviceReportPage` directly without re-fetching when possible.
  final Map<String, dynamic> report;

  ScanItem({
    required this.name,
    required this.imei,
    required this.status,
    this.serviceId,
    this.createdAt,
    this.report = const {},
  });

  String get reportId => report['_id']?.toString() ?? '';

  bool get hasSavedReport =>
      report.containsKey('ok') ||
      report.containsKey('data') ||
      report.containsKey('parsedProviderData') ||
      report.containsKey('providerData') ||
      report.containsKey('providerResults');
}
