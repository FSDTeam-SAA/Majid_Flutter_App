import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/animation/app_entrance.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../controller/repair_data.dart';
import '../utils/repair_request_formatter.dart';
import '../widgets/repair_card.dart';
import 'repair_request_details_page.dart';

class AllRepairRequestsPage extends StatefulWidget {
  const AllRepairRequestsPage({super.key});

  @override
  State<AllRepairRequestsPage> createState() => _AllRepairRequestsPageState();
}

class _AllRepairRequestsPageState extends State<AllRepairRequestsPage> {
  late final ApiClient _api;
  final TextEditingController _searchCtrl = TextEditingController();
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  List<RepairItem> _repairs = [];

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _fetchRepairs();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RepairItem> get _filteredRepairs {
    if (_searchQuery.isEmpty) {
      return _repairs;
    }

    return _repairs.where((item) {
      final haystack = [
        item.name,
        item.brand,
        item.issueLabel,
        item.issueDesc,
        item.status,
        item.date,
      ].join(' ').toLowerCase();

      return haystack.contains(_searchQuery);
    }).toList();
  }

  Future<void> _fetchRepairs({int? page}) async {
    final nextPage = page ?? _currentPage;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final res = await _api.get(
        RepairRequestEndpoints.myHistory,
        query: {'page': nextPage, 'limit': 10},
      );
      final data = res.data['data'];
      if (data is! List) {
        throw const FormatException('Invalid repair response');
      }

      final meta = res.data['meta'];
      setState(() {
        _currentPage = nextPage;
        _repairs = data
            .whereType<Map>()
            .map((item) => repairItemFromJson(Map<String, dynamic>.from(item)))
            .toList();
        _totalRecords = meta is Map
            ? ((meta['total'] as num?)?.toInt() ?? _repairs.length)
            : _repairs.length;
        _totalPages = meta is Map
            ? ((meta['totalPage'] as num?)?.toInt() ?? 1)
            : 1;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data?['message'] ?? 'Failed to load repair requests';
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Repair Requests'),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: AppLoadingIndicator(label: 'Loading repair requests...'),
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
                onPressed: _fetchRepairs,
                child: const Text('Retry'),
              ).entrance(index: 1),
            ],
          ),
        ),
      );
    }

    final filteredRepairs = _filteredRepairs;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _searchQuery.isEmpty
                    ? '$_totalRecords Records'
                    : '${filteredRepairs.length} of $_totalRecords Records',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ).entrance(enableScale: false),
              const SizedBox(height: 12),
              _buildSearchBar().entrance(index: 1),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.cardBackground,
            onRefresh: () => _fetchRepairs(page: 1),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              children: [
                if (_repairs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Text(
                        'No repair requests yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ).entrance(index: 2, enableScale: false),
                    ),
                  )
                else if (filteredRepairs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Text(
                        'No repair requests match "$_searchQuery"',
                        style: TextStyle(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ).entrance(index: 2, enableScale: false),
                    ),
                  )
                else
                  ...filteredRepairs.indexed.map(
                    (entry) => RepairCard(
                      item: entry.$2,
                      onViewReport: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RepairRequestDetailsPage(repair: entry.$2.raw),
                        ),
                      ),
                    ).entrance(index: entry.$1, begin: const Offset(0, 0.05)),
                  ),
                const SizedBox(height: 8),
                if (_totalPages > 1) _buildPagination().entrance(index: filteredRepairs.length + 1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.primary, width: 1.2),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) =>
            setState(() => _searchQuery = value.trim().toLowerCase()),
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search repair requests...',
          hintStyle: TextStyle(color: AppColors.primary, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _currentPage > 1
              ? () => _fetchRepairs(page: _currentPage - 1)
              : null,
          child: Row(
            children: [
              Icon(
                Icons.chevron_left,
                color: _currentPage > 1
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                size: 18,
              ),
              Text(
                'PREVIOUS',
                style: TextStyle(
                  color: _currentPage > 1
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildPageNumber(_currentPage),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _currentPage < _totalPages
              ? () => _fetchRepairs(page: _currentPage + 1)
              : null,
          child: Row(
            children: [
              Text(
                'NEXT',
                style: TextStyle(
                  color: _currentPage < _totalPages
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: _currentPage < _totalPages
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageNumber(int page) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$page',
          style: TextStyle(
            color: AppColors.surfaceForeground,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
