import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../controller/scan_data.dart';
import '../utils/scan_item_mapper.dart';
import 'all_scan_history_page.dart';
import 'barcode_scanner_page.dart';
import '../widgets/carrier_dropdown.dart';
import '../widgets/scan_item_card.dart';
import '../widgets/scan_search_bar.dart';
import 'device_report_page.dart';

class ScanDevicePage extends StatefulWidget {
  const ScanDevicePage({super.key});

  @override
  State<ScanDevicePage> createState() => _ScanDevicePageState();
}

final List<ScanItem> sessionScans = [];

class _ScanDevicePageState extends State<ScanDevicePage> {
  final _controller = TextEditingController();
  late final ApiClient _api;
  bool _dropdownOpen = false;
  bool _isLoading = false;
  bool _isScanning = false;
  bool _isExtractingImei = false;
  String _errorMessage = '';
  List<ScanItem> _recentScans = [];
  List<ScanDropdownOption> _services = [];
  ScanDropdownOption? _selectedService;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _loadScanData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadScanData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await Future.wait([_fetchServices(), _fetchRecentScans()]);
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Failed to load scans';
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchServices() async {
    final res = await _api.get(ImeiEndpoints.services);
    final data = res.data['data'];
    if (data is! List) {
      throw const FormatException('Invalid services response');
    }

    final services = <ScanDropdownOption>[];
    for (final group in data) {
      if (group is! Map) continue;
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

    _services = services.isEmpty ? verificationOptions : services;
    _selectedService ??= _services.firstOrNull;
  }

  Future<void> _fetchRecentScans() async {
    final res = await _api.get(ImeiEndpoints.history);
    final data = res.data['data'];
    if (data is! List) {
      throw const FormatException('Invalid scan history response');
    }
    final scans = data
        .whereType<Map>()
        .map((item) => scanItemFromJson(Map<String, dynamic>.from(item)))
        .toList();

    scans.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    final apiScans = scans
        .where((s) => s.name != 'Unknown Device' && s.name != 'IMEI Check')
        .toList();

    final apiImeis = apiScans.map((s) => s.imei).toSet();
    final extraSessionScans = sessionScans
        .where((s) => !apiImeis.contains(s.imei))
        .toList();

    _recentScans = [...extraSessionScans, ...apiScans];
    _recentScans.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
  }

  Future<void> _scanNow() async {
    final imei = _normalizeImei(_controller.text);
    final serviceId = _selectedService?.serviceId;
    if (imei.isEmpty) {
      _showMessage('Please enter an IMEI number.');
      return;
    }
    if (!_isValidImei(imei)) {
      _showMessage('Please enter a valid 15-digit IMEI number.');
      return;
    }
    if (serviceId == null) {
      _showMessage('Please select a verification service.');
      return;
    }

    _controller.text = imei;
    FocusScope.of(context).unfocus();
    setState(() => _isScanning = true);
    try {
      final res = await _api.post(
        ImeiEndpoints.checkV2,
        data: {'imei': imei, 'serviceId': serviceId},
      );
      final data = res.data['data'];
      if (data is! List || data.isEmpty) {
        throw const FormatException('Invalid scan response');
      }
      final first = data.first;
      if (first is! Map) {
        throw const FormatException('Invalid scan result');
      }
      if (first['ok'] != true) {
        _showMessage(first['message']?.toString() ?? 'IMEI check failed');
        return;
      }
      final scanResult = Map<String, dynamic>.from(first);
      final scanData = scanResult['data'];
      final hasDeviceData = _hasValidDeviceData(scanData);
      if (!hasDeviceData) {
        _showMessage('No device information found for this IMEI. Please check the IMEI and selected service.');
        return;
      }
      final newScan = _buildScanItemFromResponse(scanResult, imei);
      if (newScan != null) {
        sessionScans.removeWhere((s) => s.imei == imei);
        sessionScans.insert(0, newScan);
        setState(() {
          _recentScans.removeWhere((s) => s.imei == imei);
          _recentScans.insert(0, newScan);
        });
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeviceReportPage(report: scanResult),
        ),
      );
    } on DioException catch (e) {
      _showMessage(e.response?.data?['message'] ?? 'IMEI check failed');
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _uploadImageAndExtractImei() async {
    if (_isExtractingImei || _isScanning) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) {
      _showMessage('Please choose an image smaller than 5MB.');
      return;
    }

    setState(() => _isExtractingImei = true);
    try {
      final payload = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
      });
      final res = await _api.post(OcrEndpoints.extractImei, data: payload);
      final responseData = res.data is Map ? res.data['data'] : null;
      final imeiNumbers = _extractImeis(responseData);

      if (imeiNumbers.isEmpty) {
        _showMessage('No valid IMEI found in the selected image.');
        return;
      }

      final firstImei = imeiNumbers.first;
      _controller.text = firstImei;

      if (imeiNumbers.length == 1) {
        _showMessage('IMEI extracted successfully. Tap Scan Now to continue.');
      } else {
        _showMessage(
          '${imeiNumbers.length} IMEIs found. The first one has been filled in.',
        );
      }
    } on DioException catch (e) {
      _showMessage(
        e.response?.data?['message'] ?? 'Failed to extract IMEI from image.',
      );
    } catch (_) {
      _showMessage('Failed to extract IMEI from image.');
    } finally {
      if (mounted) setState(() => _isExtractingImei = false);
    }
  }

  Future<void> _openBarcodeScanner() async {
    if (_isScanning || _isExtractingImei) return;

    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );

    if (!mounted || scannedValue == null || scannedValue.trim().isEmpty) {
      return;
    }

    final trimmedValue = scannedValue.trim();
    _controller.text = trimmedValue;

    final normalizedImei = _normalizeImei(trimmedValue);
    if (_isValidImei(normalizedImei)) {
      _controller.text = normalizedImei;
      _showMessage('IMEI scanned successfully. Tap Scan Now to continue.');
      return;
    }

    await _lookupBarcode(trimmedValue);
  }

  Future<void> _lookupBarcode(String code) async {
    FocusScope.of(context).unfocus();
    setState(() => _isScanning = true);
    try {
      final res = await _api.get(BarcodeEndpoints.search(code));
      final data = res.data is Map ? res.data['data'] : null;
      if (data is! Map) {
        throw const FormatException('Invalid barcode response');
      }
      if (!mounted) return;
      await _showBarcodeResultSheet(Map<String, dynamic>.from(data));
    } on DioException catch (e) {
      _showMessage(e.response?.data?['message'] ?? 'Barcode lookup failed');
    } catch (_) {
      _showMessage('Barcode lookup failed');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentPreview = _recentScans.take(5).toList();

    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'Scan Device',
            trailing: UserAvatar(),
            showBackButton: false,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.cardBackground,
              onRefresh: _loadScanData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  _floatingNavClearance(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    ScanSearchBar(
                      controller: _controller,
                      onScanTap: _openBarcodeScanner,
                    ),
                    SizedBox(height: 12),
                    CarrierDropdown(
                      isOpen: _dropdownOpen,
                      options: _services.isEmpty
                          ? verificationOptions
                          : _services,
                      selected: _selectedService,
                      onToggle: () =>
                          setState(() => _dropdownOpen = !_dropdownOpen),
                      onSelect: (option) => setState(() {
                        _selectedService = option;
                        _dropdownOpen = false;
                      }),
                    ),
                    SizedBox(height: 24),
                    _buildScanNowButton(),
                    SizedBox(height: 12),
                    _buildUploadButton(),
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Scans',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AllScanHistoryPage(),
                            ),
                          ),
                          child: Text(
                            'See All (${_recentScans.length})',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    if (_isLoading) ...[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ] else if (_errorMessage.isNotEmpty) ...[
                      _buildError(),
                    ] else if (_recentScans.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No scans yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    ] else ...[
                      ...recentPreview.map(
                        (item) => ScanItemCard(
                          item: item,
                          onTap: () => _openRecentScan(item),
                        ),
                      ),
                    ],
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _floatingNavClearance(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 96;
  }

  Widget _buildScanNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isScanning || _isExtractingImei)
            ? null
            : () {
                if (_selectedService == null) {
                  _showMessage('Please select a verification service first.');
                  return;
                }
                _scanNow();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: EdgeInsets.symmetric(vertical: 17),
          elevation: 0,
        ),
        child: _isScanning
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.surfaceForeground,
                ),
              )
            : Text(
                'Scan Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: (_isExtractingImei || _isScanning)
            ? null
            : _uploadImageAndExtractImei,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          disabledForegroundColor: AppColors.textSecondary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: EdgeInsets.symmetric(vertical: 17),
        ),
        child: _isExtractingImei
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.primary,
                ),
              )
            : Text(
                'Upload Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loadScanData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBarcodeResultSheet(Map<String, dynamic> data) {
    final name = data['name']?.toString().trim();
    final brand = data['brand']?.toString().trim();
    final category = data['category']?.toString().trim();
    final barcode = data['barcode']?.toString().trim();
    final description = data['description']?.toString().trim();
    final image = data['image']?.toString().trim();

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name?.isNotEmpty == true ? name! : 'Barcode Result',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (image?.isNotEmpty == true)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      image!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                if (image?.isNotEmpty == true) const SizedBox(height: 14),
                _sheetField('Barcode', barcode ?? _controller.text.trim()),
                _sheetField('Brand', brand ?? 'N/A'),
                _sheetField('Category', category ?? 'N/A'),
                _sheetField('Description', description ?? 'N/A'),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.primary, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
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
      final directList = responseData['imeiNumbers'] ?? responseData['imeis'];
      if (directList is List) {
        for (final item in directList) {
          addCandidate(item);
        }
      }

      addCandidate(responseData['imei']);
      addCandidate(responseData['imeiNumber']);

      final rawText = responseData['rawText'];
      if (rawText is String) {
        for (final match in RegExp(r'\d{15}').allMatches(rawText)) {
          addCandidate(match.group(0));
        }
      }
    } else if (responseData is List) {
      for (final item in responseData) {
        addCandidate(item);
      }
    }

    return imeis.toList();
  }

  int? _detectServiceId(ScanItem item) {
    if (item.serviceId != null) return item.serviceId;

    final text = [
      item.name,
      item.report['deviceName']?.toString() ?? '',
      item.report['deviceModel']?.toString() ?? '',
      item.report['description']?.toString() ?? '',
    ].join(' ').toLowerCase();

    final keywordMap = {
      'iphone': ['apple', 'iphone'],
      'ipad': ['apple', 'iphone'],
      'macbook': ['apple', 'iphone'],
      'samsung': ['samsung'],
      'galaxy': ['samsung'],
      'pixel': ['pixel', 'google'],
      'redmi': ['xiaomi', 'redmi', 'basic'],
      'xiaomi': ['xiaomi', 'redmi', 'basic'],
      'poco': ['xiaomi', 'poco', 'basic'],
      'infinix': ['basic', 'info'],
      'tecno': ['basic', 'info'],
      'oppo': ['basic', 'info'],
      'vivo': ['basic', 'info'],
      'realme': ['basic', 'info'],
      'oneplus': ['basic', 'info'],
      'huawei': ['basic', 'info'],
      'nokia': ['basic', 'info'],
      'motorola': ['basic', 'info'],
    };

    List<String> matchKeywords = [];
    for (final entry in keywordMap.entries) {
      if (text.contains(entry.key)) {
        matchKeywords = entry.value;
        break;
      }
    }

    if (matchKeywords.isEmpty) return _services.firstOrNull?.serviceId;

    for (final keyword in matchKeywords) {
      for (final service in _services) {
        if (service.label.toLowerCase().contains(keyword)) {
          return service.serviceId;
        }
      }
    }

    return _services.firstOrNull?.serviceId;
  }

  Future<void> _openRecentScan(ScanItem item) async {
    if (item.report.containsKey('ok')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceReportPage(report: item.report)));
      return;
    }

    if (item.imei.isEmpty) return;
    final serviceId = _detectServiceId(item);
    if (serviceId == null) {
      _showMessage('No service available. Please try again.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text('Loading report...', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ],
          ),
        ),
      ),
    );

    try {
      final res = await _api.post(ImeiEndpoints.checkV2, data: {'imei': item.imei, 'serviceId': serviceId});
      if (!mounted) return;
      Navigator.pop(context);
      final data = res.data['data'];
      if (data is! List || data.isEmpty) {
        _showMessage('Failed to load device report.');
        return;
      }
      final first = data.first;
      if (first is! Map || first['ok'] != true) {
        _showMessage(first is Map ? first['message']?.toString() ?? 'Device data not found.' : 'Device data not found.');
        return;
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceReportPage(report: Map<String, dynamic>.from(first))));
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showMessage('Failed to load device report.');
      }
    }
  }

  bool _hasValidDeviceData(dynamic data) {
    if (data is! Map) return false;
    for (final key in ['parsedProviderData', 'providerResults']) {
      final parsed = data[key];
      if (parsed is Map && parsed.isNotEmpty) {
        final allValues = parsed.values.join(' ').toLowerCase();
        if (allValues.contains('not found') || allValues.contains('error')) return false;

        for (final nameKey in [
          'model', 'model_name',
          'description', 'device_description',
          'device_name', 'full_name',
        ]) {
          final value = parsed[nameKey]?.toString();
          if (value != null && value.isNotEmpty) return true;
        }
      }
    }
    return false;
  }

  ScanItem? _buildScanItemFromResponse(
    Map<String, dynamic> response,
    String imei,
  ) {
    final data = response['data'];
    final parsed = <String, dynamic>{};
    if (data is Map) {
      final providerResults = data['providerResults'];
      final parsedProviderData = data['parsedProviderData'];
      if (providerResults is Map) parsed.addAll(Map<String, dynamic>.from(providerResults));
      if (parsedProviderData is Map) parsed.addAll(Map<String, dynamic>.from(parsedProviderData));
    }

    String? name;
    for (final key in [
      'model_name',
      'marketing_name',
      'full_name',
      'device_description',
      'description',
      'manufacturer',
    ]) {
      final value = parsed[key]?.toString();
      if (value != null && value.isNotEmpty && value != 'Unknown Device') {
        name = value;
        break;
      }
    }

    if (name == null || name.isEmpty) return null;

    final rawStatus = response['data'] is Map
        ? response['data']['deviceStatus']?.toString()
        : null;
    final status = (rawStatus == null || rawStatus.isEmpty || rawStatus == 'unknown')
        ? 'Clean'
        : rawStatus[0].toUpperCase() + rawStatus.substring(1);

    return ScanItem(
      name: name,
      imei: imei,
      status: status,
      createdAt: DateTime.now(),
      report: response,
    );
  }

  String _normalizeImei(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  bool _isValidImei(String value) {
    return RegExp(r'^\d{15}$').hasMatch(value);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
