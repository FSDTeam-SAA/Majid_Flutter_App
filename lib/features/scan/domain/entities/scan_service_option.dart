/// A selectable IMEI verification service, as shown in the scan screen's
/// service dropdown (e.g. "Basic IMEI Check" / "Free").
class ScanDropdownOption {
  final String label;
  final String type;
  final int? serviceId;

  ScanDropdownOption(this.label, this.type, {this.serviceId});
}
