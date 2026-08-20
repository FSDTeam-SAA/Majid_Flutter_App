import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/animation/app_entrance.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../data/repositories/imei_repository_impl.dart';
import '../../domain/repositories/imei_repository.dart';
import '../controller/scan_data.dart';
import 'device_report_page.dart';
import 'scan_device_page.dart' show sessionScans;
import '../widgets/scan_item_card.dart';

class AllScanHistoryPage extends StatefulWidget {
  const AllScanHistoryPage({super.key});

  @override
  State<AllScanHistoryPage> createState() => _AllScanHistoryPageState();
}

class _AllScanHistoryPageState extends State<AllScanHistoryPage> {
  late final ImeiRepository _imeiRepository;
  bool _isLoading = true;
  String _errorMessage = '';
  List<ScanItem> _scans = [];

  @override
  void initState() {
    super.initState();
    _imeiRepository = ImeiRepositoryImpl(ApiClient(baseUrl));
    _fetchScans();
  }

  Future<void> _fetchScans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final scans = await _imeiRepository.getHistory(limit: 50);

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

      final merged = [...extraSessionScans, ...apiScans];
      merged.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      setState(() => _scans = merged);
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data?['message'] ?? 'Failed to load recent scans';
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openScan(ScanItem item) async {
    if (item.report.containsKey('ok')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DeviceReportPage(report: item.report),
        ),
      );
      return;
    }

    if (item.imei.isEmpty) return;

    final serviceId = item.serviceId;
    if (serviceId == null) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No service info available for this scan. Please scan again.',
            ),
          ),
        );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const AppLoadingIndicator(label: 'Loading report...'),
        ),
      ),
    );

    try {
      final report = await _imeiRepository.checkImei(
        imei: item.imei,
        serviceId: serviceId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DeviceReportPage(report: report)),
      );
    } on ImeiScanException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message.isNotEmpty ? e.message : 'Device data not found.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load device report.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'All Scans'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: AppLoadingIndicator(label: 'Loading scans...'),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ).entrance(enableScale: false),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _fetchScans,
                child: const Text('Retry'),
              ).entrance(index: 1),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      onRefresh: _fetchScans,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Text(
            '${_scans.length} Records',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ).entrance(enableScale: false),
          const SizedBox(height: 14),
          if (_scans.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text(
                  'No scans yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ).entrance(index: 1, enableScale: false),
              ),
            )
          else
            ..._scans.indexed.map(
              (entry) => ScanItemCard(
                item: entry.$2,
                onTap: () => _openScan(entry.$2),
              ).entrance(index: entry.$1, begin: const Offset(0, 0.05)),
            ),
        ],
      ),
    );
  }
}
