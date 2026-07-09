import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/info_field.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../staff/data/repositories/staff_repository_impl.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../controller/repair_data.dart';
import '../widgets/timeline_widget.dart';
import 'receipt_page.dart';

class RepairRequestDetailsPage extends StatefulWidget {
  final Map<String, dynamic> repair;

  const RepairRequestDetailsPage({super.key, this.repair = const {}});

  @override
  State<RepairRequestDetailsPage> createState() =>
      _RepairRequestDetailsPageState();
}

class _RepairRequestDetailsPageState extends State<RepairRequestDetailsPage> {
  late final ApiClient _api;
  late Map<String, dynamic> _repair;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _repair = Map<String, dynamic>.from(widget.repair);
  }

  Future<void> _refreshRepair() async {
    final id = _repair['_id']?.toString();
    if (id == null || id.isEmpty) return;
    try {
      final res = await _api.get(RepairRequestEndpoints.byId(id));
      final data = res.data['data'];
      if (data is Map && mounted) {
        setState(() => _repair = Map<String, dynamic>.from(data));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    final id = _repair['_id']?.toString();
    if (id == null || id.isEmpty) {
      _showMessage('Invalid repair request');
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final res = await _api.put(
        RepairRequestEndpoints.updateStatus(id),
        data: {'status': status},
      );
      final data = res.data['data'];
      if (data is Map) {
        setState(() => _repair = Map<String, dynamic>.from(data));
      } else {
        setState(() => _repair['status'] = status);
      }
      _showMessage('Status updated to ${_formatStatus(status)}');
    } on DioException catch (e) {
      _showMessage(
        e.response?.data?['message'] ?? 'Failed to update status',
      );
    } catch (e) {
      _showMessage('Failed to update status');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showWaitingForPartsDialog() async {
    final daysCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Waiting for Parts', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: daysCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Estimated days',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.fieldBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.fieldBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.fieldBorder)),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Which parts are needed?',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.fieldBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.fieldBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.fieldBorder)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final days = int.tryParse(daysCtrl.text.trim());
    final desc = descCtrl.text.trim();

    if (days == null || days <= 0) {
      _showMessage('Please enter valid estimated days');
      return;
    }
    if (desc.isEmpty) {
      _showMessage('Please describe which parts are needed');
      return;
    }

    final id = _repair['_id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() => _isUpdating = true);
    try {
      final res = await _api.put(
        RepairRequestEndpoints.updateStatus(id),
        data: {
          'status': 'waiting-for-parts',
          'waitingForPartsDays': days,
          'waitingForPartsDescription': desc,
        },
      );
      final data = res.data['data'];
      if (data is Map) {
        setState(() => _repair = Map<String, dynamic>.from(data));
      } else {
        setState(() => _repair['status'] = 'waiting-for-parts');
      }
      _showMessage('Status updated to Waiting for Parts');
    } on DioException catch (e) {
      _showMessage(e.response?.data?['message'] ?? 'Failed to update status');
    } catch (e) {
      _showMessage('Failed to update status');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<List<String>> _fetchPreviousProblems() async {
    try {
      final userId = _repair['userId']?.toString() ?? '';
      if (userId.isEmpty) return [];

      final res = await _api.get(RepairRequestEndpoints.userDescriptions(userId));
      final data = res.data['data'];
      if (data is! List) return [];

      return data
          .whereType<Map>()
          .map((item) => item['description']?.toString().trim() ?? '')
          .where((desc) => desc.isNotEmpty)
          .toSet()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StaffMember>> _fetchTechnicianOptions() async {
    try {
      final profileCtrl = Get.find<ProfileController>();
      var shopkeeperId = profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await profileCtrl.fetchProfile();
        shopkeeperId = profileCtrl.userId;
      }
      if (shopkeeperId.isEmpty) return [];
      return await StaffRepositoryImpl(_api).getStaffList(shopkeeperId);
    } catch (_) {
      return [];
    }
  }

  Future<void> _showReassignDialog() async {
    final descCtrl = TextEditingController(
      text: _repair['description']?.toString() ?? '',
    );
    String? selectedProblem;
    StaffMember? selectedTechnician;

    final previousProblems = await _fetchPreviousProblems();
    final technicians = await _fetchTechnicianOptions();

    if (!mounted) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                      'Reassigned Repair Request',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please provide the new repair issue and staff assignment.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 18),
                    _reassignSelectField(
                      label: 'Select Problem',
                      value: selectedProblem,
                      placeholder: 'Search or select a previous problem',
                      onTap: () async {
                        final choice = await _showProblemPickerSheet(ctx, previousProblems);
                        if (choice != null) {
                          setSheetState(() {
                            selectedProblem = choice;
                            descCtrl.text = choice;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _reassignSelectField(
                      label: 'Technician',
                      value: selectedTechnician?.fullName,
                      placeholder: 'Select staff',
                      onTap: () async {
                        final pick = await _showTechnicianPickerSheet(ctx, technicians);
                        if (pick != null) {
                          setSheetState(() => selectedTechnician = pick);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Problem Description',
                        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        hintText: 'Describe the issue in detail...',
                        hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                        filled: true,
                        fillColor: AppColors.fieldBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.fieldBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.fieldBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary, width: 1.3)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (descCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Please describe the issue')),
                              );
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text('Reassigned'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true) return;
    await _reassignRepair(
      description: descCtrl.text.trim(),
      technician: selectedTechnician,
    );
  }

  Widget _reassignSelectField({
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

  Future<String?> _showProblemPickerSheet(BuildContext context, List<String> problems) {
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
                  Text('Select Problem', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search or select a previous problem',
                      hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                      filled: true,
                      fillColor: AppColors.fieldBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.fieldBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.fieldBorder)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              problems.isEmpty ? 'No previous problems logged yet.' : 'No matching problems found.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                            itemBuilder: (_, index) => InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.pop(sheetCtx, filtered[index]),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.fieldBackground,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.fieldBorder),
                                ),
                                child: Text(
                                  filtered[index],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                                ),
                              ),
                            ),
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

  Future<StaffMember?> _showTechnicianPickerSheet(BuildContext context, List<StaffMember> technicians) {
    return showModalBottomSheet<StaffMember>(
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
                Text('Technician', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Assign a staff member to this repair.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                const SizedBox(height: 16),
                if (technicians.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No staff members found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  )
                else
                  ...technicians.map(
                    (staff) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.pop(sheetCtx, staff),
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
                                child: Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 19),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(staff.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(staff.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                            ],
                          ),
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
  }

  Future<void> _reassignRepair({
    required String description,
    StaffMember? technician,
  }) async {
    final id = _repair['_id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() => _isUpdating = true);
    try {
      final res = await _api.put(
        RepairRequestEndpoints.reassign(id),
        data: {
          'description': description,
          if (technician != null) 'technicianId': technician.id,
          if (technician != null) 'technicianName': technician.fullName,
        },
      );
      final data = res.data['data'];
      if (data is Map) {
        setState(() => _repair = Map<String, dynamic>.from(data));
      } else {
        setState(() => _repair['status'] = 'reassigned');
      }
      _showMessage('Repair request reassigned');
    } on DioException catch (e) {
      _showMessage(e.response?.data?['message'] ?? 'Failed to reassign repair request');
    } catch (e) {
      _showMessage('Failed to reassign repair request');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Repair Request Details'),
          Expanded(
            child: _isUpdating
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: AppColors.cardBackground,
                    onRefresh: _refreshRepair,
                    child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 14),
                        _buildDeviceAndInfoCard(),
                        SizedBox(height: 20),
                        TimelineWidget(steps: _buildTimelineSteps()),
                        SizedBox(height: 20),
                        _buildActions(context),
                        SizedBox(height: 20),
                        _buildIssueDescriptionCard(),
                        SizedBox(height: 20),
                        _buildCustomerDetails(),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }

  List<TimelineStep> _buildTimelineSteps() {
    final status = _repair['status']?.toString() ?? '';

    final statusOrder = [
      'inProgress',
      'order-assigned',
      'reassigned',
      'diagnosing',
      'quote_sent',
      'repairing',
      'waiting-for-parts',
      'completed',
    ];

    var currentIndex = statusOrder.indexOf(status);
    if (currentIndex < 0 && status == 'approved') currentIndex = 1;
    if (currentIndex < 0 && status == 'start-work') currentIndex = 5;
    if (currentIndex < 0 && status == 'inReview') currentIndex = 3;

    TimelineStatus stepStatus(int index) {
      if (currentIndex < 0) return TimelineStatus.pending;
      if (index < currentIndex) return TimelineStatus.done;
      if (index == currentIndex) return TimelineStatus.inProgress;
      return TimelineStatus.pending;
    }

    return [
      TimelineStep('Order Booked', 'Your order has been successfully created', stepStatus(0)),
      TimelineStep('Order Assigned', 'A technician has been assigned', stepStatus(1)),
      TimelineStep('Reassigned', 'The repair has been reassigned for another issue', stepStatus(2)),
      TimelineStep('Diagnosing Started', 'Technician is diagnosing the issue', stepStatus(3)),
      TimelineStep('Quote Sent', 'A quote has been sent for the repair', stepStatus(4)),
      TimelineStep('Repairing Started', 'Device is being repaired', stepStatus(5)),
      TimelineStep('Waiting for Parts', 'Repair is paused until parts arrive', stepStatus(6)),
      TimelineStep('Repair Complete', 'Repair has been successfully completed', stepStatus(7)),
    ];
  }

  Widget _buildIssueDescriptionCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Issue Description',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Text(
              _repair['description']?.toString() ?? 'No description provided',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceAndInfoCard() {
    final isDark = AppColors.isDark;
    final status = _formatStatus(_repair['status']?.toString());
    final innerCardColor = isDark
        ? AppColors.fieldBackground
        : Colors.white;
    final innerBorderColor = isDark
        ? AppColors.fieldBorder
        : const Color(0xFFE4E7EC);

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEVICE INFORMATION',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _repair['deviceModel']?.toString() ?? 'Unknown device',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _repair['description']?.toString() ?? 'No description provided',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: innerBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoField(
                  label: 'REQUEST ID',
                  value: '#${_repair['_id']?.toString() ?? 'N/A'}',
                ),
                const SizedBox(height: 12),
                InfoField(
                  label: 'SUBMITTED',
                  value: _formatDateTime(_repair['createdAt']?.toString()),
                ),
                const SizedBox(height: 12),
                InfoField(
                  label: 'SHOP',
                  value: _repair['shopName']?.toString() ?? 'Your Shop',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReceiptPage(repair: _repair)),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Make a Receipt',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final actions = [
      _RepairActionSpec(
        label: 'Order Assigned',
        tone: _RepairActionTone.orderAssigned,
        activeStatuses: const {'inProgress', 'order-assigned'},
        onTap: () => _updateStatus('inProgress'),
      ),
      _RepairActionSpec(
        label: 'Diagnosing Device',
        tone: _RepairActionTone.diagnosing,
        activeStatuses: const {'diagnosing', 'inReview'},
        onTap: () => _updateStatus('diagnosing'),
      ),
      _RepairActionSpec(
        label: 'Repairing Device',
        tone: _RepairActionTone.repairing,
        activeStatuses: const {'repairing', 'start-work'},
        onTap: () => _updateStatus('repairing'),
      ),
      _RepairActionSpec(
        label: 'Waiting for Parts',
        tone: _RepairActionTone.waiting,
        activeStatuses: const {'waiting-for-parts'},
        onTap: _showWaitingForPartsDialog,
      ),
      _RepairActionSpec(
        label: 'Completed',
        tone: _RepairActionTone.completed,
        activeStatuses: const {'completed'},
        onTap: () => _updateStatus('completed'),
      ),
      _RepairActionSpec(
        label: 'Reassigned',
        tone: _RepairActionTone.reassigned,
        activeStatuses: const {'reassigned'},
        onTap: _showReassignDialog,
      ),
    ];

    return AppCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final action in actions)
                    SizedBox(
                      width: itemWidth,
                      child: _actionBtn(action),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(_RepairActionSpec action) {
    final isCurrentStatus = action.activeStatuses.contains(
      _repair['status']?.toString(),
    );
    final visual = _actionVisual(action.tone, isCurrentStatus);

    return GestureDetector(
      onTap: _isUpdating ? null : action.onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: visual.gradient,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isCurrentStatus
                ? visual.borderColor.withValues(alpha: 0.95)
                : visual.borderColor.withValues(alpha: 0.4),
            width: isCurrentStatus ? 2 : 1,
          ),
          boxShadow: isCurrentStatus ? visual.shadows : [],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            action.label,
            maxLines: 1,
            style: TextStyle(
              color: visual.textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  _ActionVisual _actionVisual(_RepairActionTone tone, bool isCurrentStatus) {
    if (AppColors.isDark) {
      return _darkActionVisual(tone, isCurrentStatus);
    }

    return _lightActionVisual(tone, isCurrentStatus);
  }

  _ActionVisual _darkActionVisual(
    _RepairActionTone tone,
    bool isCurrentStatus,
  ) {
    final (start, end, border, text, glow) = switch (tone) {
      _RepairActionTone.orderAssigned => (
        const Color(0xFF32151A),
        const Color(0xFF291217),
        const Color(0xFF6E202C),
        const Color(0xFFFF474F),
        const Color(0xFFFF474F),
      ),
      _RepairActionTone.diagnosing => (
        const Color(0xFF10302B),
        const Color(0xFF0C2622),
        const Color(0xFF0E6650),
        const Color(0xFF22F0B6),
        const Color(0xFF22F0B6),
      ),
      _RepairActionTone.repairing => (
        const Color(0xFF392414),
        const Color(0xFF2B1C11),
        const Color(0xFF7A4215),
        const Color(0xFFFFA034),
        const Color(0xFFFFA034),
      ),
      _RepairActionTone.waiting => (
        const Color(0xFF182A46),
        const Color(0xFF142137),
        const Color(0xFF214A8E),
        const Color(0xFF3D95FF),
        const Color(0xFF3D95FF),
      ),
      _RepairActionTone.completed => (
        const Color(0xFF1C3421),
        const Color(0xFF16281A),
        const Color(0xFF325E36),
        const Color(0xFF85FF79),
        const Color(0xFF85FF79),
      ),
      _RepairActionTone.reassigned => (
        const Color(0xFF1B2350),
        const Color(0xFF141A3D),
        const Color(0xFF2E3D8E),
        const Color(0xFF6B7FFF),
        const Color(0xFF6B7FFF),
      ),
    };

    return _ActionVisual(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          start,
          end,
          end.withValues(alpha: 0.98),
        ],
      ),
      borderColor: border.withValues(alpha: isCurrentStatus ? 0.95 : 0.7),
      textColor: text,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.26),
          blurRadius: 22,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: glow.withValues(alpha: isCurrentStatus ? 0.2 : 0.1),
          blurRadius: isCurrentStatus ? 34 : 24,
          spreadRadius: isCurrentStatus ? 1.5 : 0,
        ),
      ],
    );
  }

  _ActionVisual _lightActionVisual(
    _RepairActionTone tone,
    bool isCurrentStatus,
  ) {
    final (fill, border, glow) = switch (tone) {
      _RepairActionTone.orderAssigned => (
        const Color(0xFFFF2B31),
        const Color(0xFFFF2B31),
        const Color(0xFFFF5F69),
      ),
      _RepairActionTone.diagnosing => (
        const Color(0xFF10C184),
        const Color(0xFF10C184),
        const Color(0xFF46D6A7),
      ),
      _RepairActionTone.repairing => (
        const Color(0xFFFF7A00),
        const Color(0xFFFF7A00),
        const Color(0xFFFFB05A),
      ),
      _RepairActionTone.waiting => (
        const Color(0xFF3A7DF2),
        const Color(0xFF3A7DF2),
        const Color(0xFF71A4FF),
      ),
      _RepairActionTone.completed => (
        const Color(0xFF1B56EA),
        const Color(0xFF1B56EA),
        const Color(0xFF6E9BFF),
      ),
      _RepairActionTone.reassigned => (
        const Color(0xFF2B3A9E),
        const Color(0xFF2B3A9E),
        const Color(0xFF6E7FE0),
      ),
    };

    return _ActionVisual(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          fill,
          Color.lerp(fill, Colors.white, 0.06)!,
        ],
      ),
      borderColor: border.withValues(alpha: isCurrentStatus ? 1 : 0.88),
      textColor: Colors.white,
      shadows: [
        BoxShadow(
          color: glow.withValues(alpha: isCurrentStatus ? 0.28 : 0.18),
          blurRadius: isCurrentStatus ? 30 : 22,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildCustomerDetails() {
    final isDark = AppColors.isDark;
    final innerCardColor = isDark ? AppColors.fieldBackground : Colors.white;
    final innerBorderColor = isDark ? AppColors.fieldBorder : const Color(0xFFE4E7EC);

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CUSTOMER DETAILS',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: innerCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: innerBorderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoField(
                  label: 'NAME',
                  value: _repair['firstName']?.toString() ?? '',
                ),
                const SizedBox(height: 14),
                InfoField(
                  label: 'EMAIL ADDRESS',
                  value: _repair['email']?.toString() ?? '',
                ),
                const SizedBox(height: 14),
                InfoField(
                  label: 'PHONE NUMBER',
                  value: _repair['phoneNumber']?.toString() ?? '',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String? status) {
    return switch (status) {
      'inProgress' => 'In Progress',
      'approved' => 'Approved',
      'rejected' => 'Rejected',
      'completed' => 'Completed',
      'inReview' => 'In Review',
      'start-work' => 'Start Work',
      'quote-sent' => 'Quote Sent',
      'waiting-for-parts' => 'Waiting for Parts',
      'diagnosing' => 'Diagnosing',
      'repairing' => 'Repairing',
      'order-assigned' => 'Order Assigned',
      'reassigned' => 'Reassigned',
      null || '' => 'In Progress',
      _ => status,
    };
  }

  String _formatDateTime(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${months[local.month - 1]} ${local.day.toString().padLeft(2, '0')}, ${local.year} · $hour:$minute $period';
  }
}

enum _RepairActionTone {
  orderAssigned,
  diagnosing,
  repairing,
  waiting,
  completed,
  reassigned,
}

class _RepairActionSpec {
  final String label;
  final _RepairActionTone tone;
  final Set<String> activeStatuses;
  final VoidCallback onTap;

  const _RepairActionSpec({
    required this.label,
    required this.tone,
    required this.activeStatuses,
    required this.onTap,
  });
}

class _ActionVisual {
  final LinearGradient gradient;
  final Color borderColor;
  final Color textColor;
  final List<BoxShadow> shadows;

  const _ActionVisual({
    required this.gradient,
    required this.borderColor,
    required this.textColor,
    required this.shadows,
  });
}
