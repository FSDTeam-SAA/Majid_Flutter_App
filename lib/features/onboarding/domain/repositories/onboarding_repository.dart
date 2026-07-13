import '../../../scan/domain/entities/scan_service_option.dart';

/// Thrown by [OnboardingRepository.checkImeiFree] when the free IMEI check
/// completes but does not return usable device data. The [message] mirrors
/// the text previously shown directly in the UI's SnackBars.
class OnboardingScanException implements Exception {
  final String message;

  const OnboardingScanException(this.message);

  @override
  String toString() => message;
}

abstract class OnboardingRepository {
  /// Fetches the list of free IMEI-check services available for anonymous
  /// / first-time users, reusing the shared [ScanDropdownOption] model.
  Future<List<ScanDropdownOption>> getFreeServices();

  /// Submits a free IMEI check and returns the parsed device report map
  /// (the same shape expected by `DeviceReportPage`).
  ///
  /// Throws an [OnboardingScanException] when the response does not contain
  /// a usable report (e.g. empty result set or `ok != true`).
  Future<Map<String, dynamic>> checkImeiFree({
    required String imei,
    required int serviceId,
  });
}
