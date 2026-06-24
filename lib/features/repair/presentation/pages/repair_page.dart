import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../controller/repair_data.dart';
import '../widgets/repair_card.dart';
import '../widgets/repair_stats_row.dart';
import 'repair_request_details_page.dart';

class RepairPage extends StatefulWidget {
  const RepairPage({super.key});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  late final ApiClient _api;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  bool _isLoading = true;
  String _errorMessage = '';
  List<RepairItem> _repairs = [];

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _fetchRepairs();
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
            .map((item) => _repairFromJson(Map<String, dynamic>.from(item)))
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

  RepairItem _repairFromJson(Map<String, dynamic> item) {
    return RepairItem(
      name: item['firstName']?.toString() ?? 'Customer',
      brand: item['deviceModel']?.toString() ?? 'Unknown device',
      issueLabel: 'Issue Summary',
      issueDesc: item['description']?.toString() ?? 'No description provided',
      date: _formatDate(item['createdAt']?.toString()),
      status: _formatStatus(item['status']?.toString()),
      price: (item['price'] as num?)?.toDouble() ?? 0,
      raw: item,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'Repair Requests',
            trailing: UserAvatar(),
            showBackButton: false,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
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
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _fetchRepairs,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final completed = _repairs
        .where((item) => item.status == 'Completed')
        .length;
    final inProgress = _repairs.length - completed;
    final totalSales = _repairs.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      onRefresh: _fetchRepairs,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            RepairStatsRow(
              inProgress: inProgress,
              completed: completed,
              totalSales: totalSales,
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Create Repair Request',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Repair request form is coming soon.'),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(),
            const SizedBox(height: 14),
            if (_repairs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'No repair requests yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ..._repairs.map(
                (item) => RepairCard(
                  item: item,
                  onViewReport: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RepairRequestDetailsPage(repair: item.raw),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (_totalPages > 1) _buildPagination(),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Repair Requests',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$_totalRecords Records',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
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

  String _formatStatus(String? status) {
    return switch (status) {
      'completed' => 'Completed',
      'inProgress' ||
      'quote_sent' ||
      'approved' ||
      'inReview' ||
      'start-work' ||
      'waiting-for-parts' ||
      'order-assigned' ||
      'diagnosing' ||
      'repairing' => 'In Progress',
      'rejected' => 'Rejected',
      _ => status ?? 'In Progress',
    };
  }

  String _formatDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day.toString().padLeft(2, '0')}, ${local.year}';
  }
}
