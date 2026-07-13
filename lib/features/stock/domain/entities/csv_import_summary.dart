/// Result summary returned by the inventory CSV/XLS/XLSX bulk import
/// endpoint.
class CsvImportSummary {
  final int? successCount;
  final int? failureCount;

  const CsvImportSummary({this.successCount, this.failureCount});
}
