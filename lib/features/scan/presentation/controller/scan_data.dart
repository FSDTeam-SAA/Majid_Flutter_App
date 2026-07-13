// `ScanItem` and `ScanDropdownOption` now live in `domain/entities/` as the
// scan feature's proper domain models; they're re-exported here so existing
// presentation-layer imports of this file keep working unchanged.
export '../../domain/entities/scan_item.dart';
export '../../domain/entities/scan_service_option.dart';

import '../../domain/entities/scan_service_option.dart';

/// Fallback verification services shown while the real list is loading (or
/// if the API returns none), so the dropdown is never empty.
List<ScanDropdownOption> verificationOptions = [
  ScanDropdownOption('Basic IMEI Check', 'Free'),
  ScanDropdownOption('Carrier Lock Status', 'Free'),
  ScanDropdownOption('Blacklist Check', 'Free'),
  ScanDropdownOption('iCloud Lock', 'Premium'),
  ScanDropdownOption('MDM Status', 'Premium'),
];
