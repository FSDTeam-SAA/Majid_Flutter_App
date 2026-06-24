class ScanItem {
  final String name;
  final String imei;
  final String status;
  ScanItem({required this.name, required this.imei, required this.status});
}

class ScanDropdownOption {
  final String label;
  final String type;
  final int? serviceId;
  ScanDropdownOption(this.label, this.type, {this.serviceId});
}

List<ScanItem> recentScans = [
  ScanItem(
    name: 'iPhone 15 Pro Max',
    imei: '35 901234 567890',
    status: 'Clean',
  ),
  ScanItem(
    name: 'Samsung S24 Ultra',
    imei: '35 901234 567890',
    status: 'Blacklisted',
  ),
  ScanItem(
    name: 'Google Pixel 8 Pro',
    imei: '35 901234 567890',
    status: 'Clean',
  ),
  ScanItem(name: 'OnePlus 11', imei: '35 901234 567890', status: 'Active'),
  ScanItem(name: 'Xiaomi 13 Pro', imei: '35 901234 567890', status: 'Clean'),
  ScanItem(
    name: 'Sony Xperia 1 V',
    imei: '35 901234 567890',
    status: 'Blacklisted',
  ),
];

List<ScanDropdownOption> verificationOptions = [
  ScanDropdownOption('Basic IMEI Check', 'Free'),
  ScanDropdownOption('Carrier Lock Status', 'Free'),
  ScanDropdownOption('Blacklist Check', 'Free'),
  ScanDropdownOption('iCloud Lock', 'Premium'),
  ScanDropdownOption('MDM Status', 'Premium'),
];
