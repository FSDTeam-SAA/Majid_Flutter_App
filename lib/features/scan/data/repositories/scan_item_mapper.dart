import '../../domain/entities/scan_item.dart';

String _resolveDeviceName(Map<String, dynamic> item) {
  final deviceName = item['deviceName']?.toString();
  if (deviceName != null && deviceName != 'Unknown Device') {
    return deviceName;
  }

  final model = item['model']?.toString();
  if (model != null && model != 'Unknown Device') return model;

  final providerData = item['providerData'];
  if (providerData is Map) {
    final providerModel = providerData['model']?.toString();
    if (providerModel != null) return providerModel;
  }

  final data = item['data'];
  if (data is Map) {
    final dataName = data['deviceName']?.toString();
    if (dataName != null && dataName != 'Unknown Device') return dataName;
  }

  final parsed = item['parsedProviderData'];
  if (parsed is Map) {
    final deviceDescription = parsed['device_description']?.toString();
    if (deviceDescription != null && deviceDescription.isNotEmpty)
      return deviceDescription;

    final description = parsed['description']?.toString();
    if (description != null && description.isNotEmpty) return description;

    final fullName = parsed['full_name']?.toString();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final marketingName = parsed['marketing_name']?.toString();
    if (marketingName != null && marketingName.isNotEmpty) return marketingName;

    final modelName = parsed['model_name']?.toString();
    if (modelName != null && modelName.isNotEmpty) return modelName;
  }

  return 'IMEI Check';
}

String _resolveStatus(String? status) {
  if (status == null || status.isEmpty || status == 'unknown') {
    return 'Clean';
  }
  return status[0].toUpperCase() + status.substring(1);
}

/// Parses a single raw scan-history JSON object (as returned by
/// `ImeiEndpoints.history`) into a [ScanItem].
ScanItem scanItemFromJson(Map<String, dynamic> item) {
  final imei = item['imei']?.toString() ?? item['IMEI']?.toString() ?? '';
  final name = _resolveDeviceName(item);

  return ScanItem(
    name: name,
    imei: imei,
    status: _resolveStatus(
      item['deviceStatus']?.toString() ?? item['status']?.toString(),
    ),
    serviceId: (item['serviceId'] as num?)?.toInt(),
    createdAt: DateTime.tryParse(
      item['createdAt']?.toString() ?? '',
    )?.toLocal(),
    report: item,
  );
}
