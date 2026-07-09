import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../core/utils/sound_effects.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../staff/data/repositories/staff_repository_impl.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../../../staff/presentation/pages/staff_page.dart';
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

  Future<List<String>> _fetchPreviousProblems() async {
    try {
      final profileCtrl = Get.find<ProfileController>();
      var userId = profileCtrl.userId;
      if (userId.isEmpty) {
        await profileCtrl.fetchProfile();
        userId = profileCtrl.userId;
      }
      if (userId.isEmpty) return [];

      final res = await _api.get(RepairRequestEndpoints.userDescriptions(userId));
      final data = res.data['data'];
      if (data is! List) return [];

      final descriptions = data
          .whereType<Map>()
          .map((item) => item['description']?.toString().trim() ?? '')
          .where((desc) => desc.isNotEmpty)
          .toSet()
          .toList();
      return descriptions;
    } catch (_) {
      return [];
    }
  }

  Future<List<StaffMember>> _fetchTechnicianOptions() async {
    try {
      final profileCtrl = Get.find<ProfileController>();
      var userId = profileCtrl.userId;
      if (userId.isEmpty) {
        await profileCtrl.fetchProfile();
        userId = profileCtrl.userId;
      }
      if (userId.isEmpty) return [];
      return await StaffRepositoryImpl(_api).getStaffList(userId);
    } catch (_) {
      return [];
    }
  }

  Future<void> _showCreateRepairSheet() async {
    final deviceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final firstNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedProblem;
    StaffMember? selectedTechnician;

    final previousProblems = await _fetchPreviousProblems();

    if (!mounted) return;

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
                    _sheetSelectField(
                      label: 'Select Problem',
                      value: selectedProblem,
                      placeholder: 'Search or select a previous problem',
                      onTap: () async {
                        final choice = await _showSearchableProblemSheet(ctx, previousProblems);
                        if (choice != null) {
                          setSheetState(() {
                            selectedProblem = choice;
                            if (descCtrl.text.trim().isEmpty) descCtrl.text = choice;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    _sheetSelectField(
                      label: 'Technician',
                      value: selectedTechnician?.fullName,
                      placeholder: 'Select staff',
                      onTap: () => _openTechnicianPicker(
                        ctx,
                        (staff) => setSheetState(() => selectedTechnician = staff),
                      ),
                    ),
                    SizedBox(height: 10),
                    _sheetField(
                      descCtrl,
                      'Problem Description',
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
                                      if (selectedTechnician != null) 'technicianId': selectedTechnician!.id,
                                      if (selectedTechnician != null) 'technicianName': selectedTechnician!.fullName,
                                    },
                                  );
                                  SoundEffects.playNewOrderBooked();
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
                          foregroundColor: AppColors.surfaceForeground,
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
                                  color: AppColors.surfaceForeground,
                                ),
                              )
                            : Text(
                                'Submit',
                                style: TextStyle(
                                  color: AppColors.surfaceForeground,
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

  Widget _sheetSelectField({
    required String label,
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          floatingLabelStyle: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
          filled: true,
          fillColor: AppColors.fieldBackground,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.fieldBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.fieldBorder)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value != null ? AppColors.textPrimary : AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<String?> _showSearchableProblemSheet(BuildContext context, List<String> problems) async {
    final searchCtrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = query.isEmpty ? problems : problems.where((p) => p.toLowerCase().contains(query)).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.fieldBorder, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Select Problem', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Reuse a problem you\'ve logged before, or type to search.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.primary.withValues(alpha: AppColors.isDark ? 0.6 : 0.72), width: 1.2),
                    ),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search or select a previous problem',
                        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: problems.isEmpty
                        ? _buildEmptyProblemState()
                        : filtered.isEmpty
                        ? _buildEmptyProblemState(message: 'No matching problems found.')
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final item = filtered[index];
                              return _buildProblemTile(item, onTap: () => Navigator.pop(sheetCtx, item));
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProblemTile(String label, {required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.history_rounded, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProblemState({String message = 'No previous problems logged yet.'}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.search_off_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Future<void> _openTechnicianPicker(BuildContext ctx, void Function(StaffMember?) onSelect) async {
    final technicians = await _fetchTechnicianOptions();
    if (!ctx.mounted) return;
    final pick = await _showTechnicianSheet(ctx, technicians);
    if (!ctx.mounted || pick == null) return;
    if (pick.openStaffPage) {
      await Navigator.push(ctx, MaterialPageRoute(builder: (_) => const StaffPage()));
      if (ctx.mounted) await _openTechnicianPicker(ctx, onSelect);
      return;
    }
    onSelect(pick.staff);
  }

  Future<_TechnicianPick?> _showTechnicianSheet(BuildContext context, List<StaffMember> technicians) {
    return showModalBottomSheet<_TechnicianPick>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.fieldBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Technician', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Assign a staff member to this repair.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                const SizedBox(height: 18),
                if (technicians.isEmpty)
                  _buildEmptyTechnicianState(sheetCtx)
                else ...[
                  _buildTechnicianTile(
                    sheetCtx,
                    icon: Icons.person_off_outlined,
                    title: 'Unassigned',
                    subtitle: 'No technician assigned yet',
                    onTap: () => Navigator.pop(sheetCtx, const _TechnicianPick(null)),
                  ),
                  const SizedBox(height: 8),
                  ...technicians.map(
                    (staff) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildTechnicianTile(
                        sheetCtx,
                        icon: Icons.person_outline_rounded,
                        title: staff.fullName,
                        subtitle: staff.email,
                        onTap: () => Navigator.pop(sheetCtx, _TechnicianPick(staff)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTechnicianTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTechnicianState(BuildContext sheetCtx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Icon(Icons.groups_2_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            'No staff members yet',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a staff member to assign repairs to a technician.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(sheetCtx, const _TechnicianPick(null, openStaffPage: true)),
            icon: Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 16),
            label: Text('Add Staff Member', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
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

class _TechnicianPick {
  final StaffMember? staff;
  final bool openStaffPage;

  const _TechnicianPick(this.staff, {this.openStaffPage = false});
}
