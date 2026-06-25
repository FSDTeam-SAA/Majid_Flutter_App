import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../controller/scan_data.dart';
import '../widgets/carrier_dropdown.dart';
import '../widgets/scan_item_card.dart';
import '../widgets/scan_search_bar.dart';
import 'device_report_page.dart';

class ScanDevicePage extends StatefulWidget {
  const ScanDevicePage({super.key});

  @override
  State<ScanDevicePage> createState() => _ScanDevicePageState();
}

class _ScanDevicePageState extends State<ScanDevicePage> {
  final _controller = TextEditingController();
  late final ApiClient _api;
  bool _dropdownOpen = false;
  bool _isLoading = false;
  bool _isScanning = false;
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
    _recentScans = data
        .whereType<Map>()
        .map((item) => _scanItemFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _scanNow() async {
    final imei = _controller.text.trim();
    final serviceId = _selectedService?.serviceId;
    if (imei.isEmpty) {
      _showMessage('Please enter an IMEI number.');
      return;
    }
    if (serviceId == null) {
      _showMessage('Please select a verification service.');
      return;
    }

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
      await _fetchRecentScans();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DeviceReportPage(report: Map<String, dynamic>.from(first)),
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

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'Scan Device',
            trailing: UserAvatar(),
            showBackButton: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  ScanSearchBar(controller: _controller),
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
                  Text(
                    'Recent Scans',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 14),
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (_errorMessage.isNotEmpty)
                    _buildError()
                  else if (_recentScans.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No scans yet',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._recentScans.map((item) => ScanItemCard(item: item)),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanNowButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isScanning ? null : _scanNow,
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
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image upload will be connected when file picking is added.',
              ),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: EdgeInsets.symmetric(vertical: 17),
        ),
        child: Text(
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

  ScanItem _scanItemFromJson(Map<String, dynamic> item) {
    final imei = item['imei']?.toString() ?? item['IMEI']?.toString() ?? '';
    final providerData = item['providerData'];
    final data = item['data'];
    final name =
        item['deviceName']?.toString() ??
        item['model']?.toString() ??
        (providerData is Map ? providerData['model']?.toString() : null) ??
        (data is Map ? data['deviceName']?.toString() : null) ??
        'IMEI Check';
    return ScanItem(
      name: name,
      imei: imei,
      status: item['status']?.toString() ?? 'Clean',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
