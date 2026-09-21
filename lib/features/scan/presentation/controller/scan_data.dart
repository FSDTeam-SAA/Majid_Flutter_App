// `ScanItem` and `ScanDropdownOption` now live in `domain/entities/` as the
// scan feature's proper domain models; they're re-exported here so existing
// presentation-layer imports of this file keep working unchanged.
export '../../domain/entities/scan_item.dart';
export '../../domain/entities/scan_service_option.dart';

import '../../domain/entities/scan_service_option.dart';

/// Fallback verification services shown while the real list is loading (or
/// if the API returns none), so the dropdown is never empty and has valid IDs.
List<ScanDropdownOption> verificationOptions = [
  ScanDropdownOption('iPhone all in one /best before buy', '0.49\$', serviceId: 1000),
  ScanDropdownOption('Samsung full report / best before buy', '0.79\$', serviceId: 1002),
  ScanDropdownOption('Mac full check /best before buy', '1.29\$', serviceId: 1001),
  ScanDropdownOption('Apple Basic Info', 'Premium', serviceId: 30),
  ScanDropdownOption('Brand & Model Info', 'Premium', serviceId: 203),
];
