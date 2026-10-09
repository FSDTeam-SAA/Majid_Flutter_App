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
import 'barcode_scanner_page.dart';
import 'scan_device_page.dart' show sessionScans;
import '../widgets/scan_item_card.dart';

class AllScanHistoryPage extends StatefulWidget {
  const AllScanHistoryPage({
    super.key,
    this.initialQuery = '',
    this.repository,
  });
  final String initialQuery;
  final ImeiRepository? repository;

  @override
  State<AllScanHistoryPage> createState() => _AllScanHistoryPageState();
}

class _AllScanHistoryPageState extends State<AllScanHistoryPage> {
  late final ImeiRepository _imeiRepository;
  bool _isLoading = true;
  String _errorMessage = '';
  int _totalCount = 0;
  List<ScanItem> _scans = [];
  late final _search = TextEditingController(text: widget.initialQuery);
  int _page = 1;
  int _totalPages = 1;
  bool _loadingOlder = false;
  List<ScanItem> get _matches {
    final query = _search.text.trim().toLowerCase();
    return _scans
        .where(
          (s) => '${s.name} ${s.imei} ${s.report['customerName'] ?? ''}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scanSearch() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (!mounted || code == null) return;
    setState(() => _search.text = code);
    await _loadOlder(searchAll: true);
  }

  Future<void> _loadOlder({bool searchAll = false}) async {
    if (_loadingOlder || _page >= _totalPages) return;
    setState(() => _loadingOlder = true);
    try {
      do {
        final result = await _imeiRepository.getHistoryResult(
          page: _page + 1,
          limit: 50,
        );
        if (!mounted) return;
        final known = _scans
            .map((s) => s.reportId)
            .where((id) => id.isNotEmpty)
            .toSet();
        setState(() {
          _scans.addAll(
            result.items.where(
              (s) => s.reportId.isEmpty || !known.contains(s.reportId),
            ),
          );
          _page = result.page;
          _totalPages = result.totalPage;
        });
      } while (searchAll && mounted && _page < _totalPages);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load older reports. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _imeiRepository =
        widget.repository ?? ImeiRepositoryImpl(ApiClient(baseUrl));
    _fetchScans();
  }

  Future<void> _fetchScans() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _imeiRepository.getHistoryResult(page: 1, limit: 50);
      if (!mounted) return;
      _page = result.page;
      _totalPages = result.totalPage;
      final scans = result.items;

      scans.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      final apiScans = scans;

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

      setState(() {
        _scans = merged;
        _totalCount = result.total + extraSessionScans.length;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            e.response?.data?['message'] ?? 'Failed to load recent scans';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openScan(ScanItem item) async {
    if (item.hasSavedReport) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DeviceReportPage(report: {...item.report, 'fromHistory': true}),
        ),
      );
      return;
    }

    if (item.reportId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved device report is not available for this scan.'),
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
      final report = await _imeiRepository.getHistoryReport(item.reportId);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DeviceReportPage(report: {...report, 'fromHistory': true}),
        ),
      );
    } on ImeiScanException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message.isNotEmpty
                  ? e.message
                  : 'Saved device report could not be loaded.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load saved device report.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Device Reports'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _loadOlder(searchAll: true),
              decoration: InputDecoration(
                hintText:
                    'Search IMEI or device · press Search for older reports',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanSearch,
                ),
              ),
            ),
          ),
          if (_search.text.trim().isNotEmpty && _page < _totalPages)
            TextButton(
              onPressed: _loadingOlder
                  ? null
                  : () => _loadOlder(searchAll: true),
              child: Text(
                _loadingOlder
                    ? 'Searching older reports...'
                    : 'Search all older reports',
              ),
            ),
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
            '$_totalCount Records',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ).entrance(enableScale: false),
          const SizedBox(height: 14),
          if (_matches.isEmpty)
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
            ..._matches.indexed.map(
              (entry) => ScanItemCard(
                item: entry.$2,
                onTap: () => _openScan(entry.$2),
              ).entrance(index: entry.$1, begin: const Offset(0, 0.05)),
            ),
          if (_page < _totalPages)
            TextButton(
              onPressed: _loadingOlder ? null : () => _loadOlder(),
              child: Text(_loadingOlder ? 'Loading...' : 'Load older reports'),
            ),
        ],
      ),
    );
  }
}
