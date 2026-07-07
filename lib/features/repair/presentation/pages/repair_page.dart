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
import '../utils/repair_request_formatter.dart';
import '../widgets/repair_card.dart';
import '../widgets/repair_stats_row.dart';
import 'all_repair_requests_page.dart';
import 'repair_request_details_page.dart';

class RepairPage extends StatefulWidget {
  const RepairPage({super.key});

  @override
  State<RepairPage> createState() => _RepairPageState();
}

class _RepairPageState extends State<RepairPage> {
  late final ApiClient _api;
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

  List<RepairItem> get _recentRepairs {
    final sortedRepairs = [..._repairs]
      ..sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    return sortedRepairs.take(5).toList();
  }

  Future<void> _fetchRepairs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final res = await _api.get(
        RepairRequestEndpoints.myHistory,
        query: {'page': 1, 'limit': 10},
      );
      final data = res.data['data'];
      if (data is! List) {
        throw const FormatException('Invalid repair response');
      }
      final meta = res.data['meta'];
      setState(() {
        _repairs = data
            .whereType<Map>()
            .map((item) => repairItemFromJson(Map<String, dynamic>.from(item)))
            .toList();
        _totalRecords = meta is Map
            ? ((meta['total'] as num?)?.toInt() ?? _repairs.length)
            : _repairs.length;
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

  Future<void> _showCreateRepairSheet() async {
    final deviceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final firstNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                18,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Repair Request',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 16),
                    _sheetField(
                      deviceCtrl,
                      'Device Model',
                      'e.g. iPhone 14 Pro',
                    ),
                    SizedBox(height: 10),
                    _sheetField(
                      descCtrl,
                      'Issue Description',
                      'Describe the problem...',
                      maxLines: 3,
                    ),
                    SizedBox(height: 10),
                    _sheetField(firstNameCtrl, 'Customer Name', 'First name'),
                    SizedBox(height: 10),
                    _sheetField(
                      emailCtrl,
                      'Customer Email',
                      'email@example.com',
                    ),
                    SizedBox(height: 10),
                    _sheetField(phoneCtrl, 'Phone Number', '+44...'),
                    SizedBox(height: 10),
                    _sheetField(
                      priceCtrl,
                      'Repair Price',
                      '0.00',
                      keyboard: TextInputType.number,
                    ),
                    SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (deviceCtrl.text.trim().isEmpty ||
                                    descCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Device and description are required',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setSheetState(() => isSaving = true);
                                try {
                                  await _api.post(
                                    RepairRequestEndpoints.add,
                                    data: {
                                      'deviceModel': deviceCtrl.text.trim(),
                                      'description': descCtrl.text.trim(),
                                      'firstName': firstNameCtrl.text.trim(),
                                      'email': emailCtrl.text.trim(),
                                      'phoneNumber': phoneCtrl.text.trim(),
                                      'price':
                                          double.tryParse(
                                            priceCtrl.text.trim(),
                                          ) ??
                                          0,
                                    },
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx, true);
                                } on DioException catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          e.response?.data?['message'] ??
                                              'Failed to create repair request',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to create repair request',
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setSheetState(() => isSaving = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isSaving
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      _fetchRepairs();
    }
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        floatingLabelStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        filled: true,
        fillColor: AppColors.fieldBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.3),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.fieldBorder.withValues(alpha: 0.7),
          ),
        ),
      ),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                RepairStatsRow(
                  inProgress: inProgress,
                  completed: completed,
                  totalSales: totalSales,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: 'Create Repair Request',
                  onPressed: _showCreateRepairSheet,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    ..._recentRepairs.map(
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
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ],
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
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AllRepairRequestsPage()),
          ),
          child: Text(
            'See All ($_totalRecords)',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
