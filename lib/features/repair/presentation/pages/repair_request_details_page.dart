import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/info_field.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../staff/data/repositories/staff_repository_impl.dart';
import '../../data/repair_parts_repository.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../controller/repair_data.dart';
import '../utils/repair_contact_uri.dart';
import '../utils/repair_timeline.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/waiting_for_parts_sheet.dart';
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
      if (status == 'completed' && mounted) {
        await _showCompletionContactSheet(autoOpened: true);
      }
    } on DioException catch (e) {
      _showMessage(e.response?.data?['message'] ?? 'Failed to update status');
    } catch (e) {
      _showMessage('Failed to update status');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<List<String>> _fetchPartSuggestions() async {
    try {
      return await RepairPartsRepository(_api).names();
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Could not load saved parts. You can retry or enter a part name.',
        );
      }
      return const [];
    }
  }

  Future<void> _showWaitingForPartsDialog() async {
    final suggestions = await _fetchPartSuggestions();
    if (!mounted) return;

    final result = await showWaitingForPartsSheet(
      context: context,
      customerName: _customerName,
      partSuggestions: suggestions,
      onCreatePart: RepairPartsRepository(_api).create,
    );
    if (result == null || !mounted) return;

    final id = _repair['_id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() => _isUpdating = true);
    try {
      final res = await _api.put(
        RepairRequestEndpoints.updateStatus(id),
        data: {
          'status': 'waiting-for-parts',
          'waitingForPartsDays': result.days,
          // The backend keeps a single free-text field, so the part and its
          // source are folded into the description.
          'waitingForPartsDescription': result.description,
        },
      );
      final data = res.data['data'];
      if (data is Map) {
        setState(() => _repair = Map<String, dynamic>.from(data));
      } else {
        setState(() => _repair['status'] = 'waiting-for-parts');
      }
      _showMessage('Status updated to Waiting for Parts');
      if (mounted) await _showNotifySheet(result.message);
    } on DioException catch (e) {
      _showMessage(e.response?.data?['message'] ?? 'Failed to update status');
    } catch (e) {
      _showMessage('Failed to update status');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  /// Sends [message] through an app chosen by the shopkeeper.
  Future<void> _showNotifySheet(String message) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notify Customer',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Send the parts update through WhatsApp, message, or email.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _contactActionChip(
                    label: 'WhatsApp',
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () => _sendOnWhatsApp(message),
                  ),
                  _contactActionChip(
                    label: 'Message',
                    icon: Icons.sms_outlined,
                    onTap: () => _sendBySms(message),
                  ),
                  _contactActionChip(
                    label: 'Email',
                    icon: Icons.mail_outline_rounded,
                    onTap: () => _sendByEmail(
                      message,
                      subject: 'Update on your repair - $_shopName',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendOnWhatsApp(String message) async {
    final phone = _sanitizePhoneNumber(_customerPhone);
    if (phone.isEmpty) {
      _showMessage('Customer phone number is missing');
      return;
    }
    await _launchUri(
      repairWhatsAppUri(phone, message),
      successLabel: 'WhatsApp',
      fallbackShareText: message,
    );
  }

  Future<void> _sendBySms(String message) async {
    final phone = _sanitizePhoneNumber(_customerPhone);
    if (phone.isEmpty) {
      _showMessage('Customer phone number is missing');
      return;
    }
    await _launchUri(
      repairSmsUri(phone, message),
      successLabel: 'messages',
      fallbackShareText: message,
    );
  }

  Future<void> _sendByEmail(String message, {required String subject}) async {
    if (_customerEmail.isEmpty) {
      _showMessage('Customer email is missing');
      return;
    }
    await _launchUri(
      repairEmailUri(_customerEmail, subject: subject, body: message),
      successLabel: 'email',
      fallbackShareText: message,
    );
  }

  Future<List<String>> _fetchPreviousProblems() async {
    try {
      final userId = _repair['userId']?.toString() ?? '';
      if (userId.isEmpty) return [];

      final res = await _api.get(
        RepairRequestEndpoints.userDescriptions(userId),
      );
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
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _reassignSelectField(
                      label: 'Select Problem',
                      value: selectedProblem,
                      placeholder: 'Search or select a previous problem',
                      onTap: () async {
                        final choice = await _showProblemPickerSheet(
                          ctx,
                          previousProblems,
                        );
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
                        final pick = await _showTechnicianPickerSheet(
                          ctx,
                          technicians,
                        );
                        if (pick != null) {
                          setSheetState(() => selectedTechnician = pick);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Problem Description',
                        labelStyle: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        hintText: 'Describe the issue in detail...',
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
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (descCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Please describe the issue'),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.fieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppColors.fieldBorder),
          ),
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
                  color: value != null
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showProblemPickerSheet(
    BuildContext context,
    List<String> problems,
  ) {
    final searchCtrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setState) {
            final query = searchCtrl.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? problems
                : problems
                      .where((p) => p.toLowerCase().contains(query))
                      .toList();
            final customProblem = searchCtrl.text.trim();
            final hasExactCustomMatch = problems.any(
              (problem) => problem.trim().toLowerCase() == query,
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Problem',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search or select a previous problem',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
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
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: filtered.isEmpty && customProblem.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              problems.isEmpty
                                  ? 'No previous problems logged yet.'
                                  : 'No matching problems found.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount:
                                filtered.length +
                                ((!hasExactCustomMatch &&
                                        customProblem.isNotEmpty)
                                    ? 1
                                    : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              if (!hasExactCustomMatch &&
                                  customProblem.isNotEmpty &&
                                  index == 0) {
                                return InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () =>
                                      Navigator.pop(sheetCtx, customProblem),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.fieldBackground,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.fieldBorder,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_note_rounded,
                                          color: AppColors.primary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Use "$customProblem"',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final filteredIndex =
                                  (!hasExactCustomMatch &&
                                      customProblem.isNotEmpty)
                                  ? index - 1
                                  : index;
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => Navigator.pop(
                                  sheetCtx,
                                  filtered[filteredIndex],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.fieldBackground,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.fieldBorder,
                                    ),
                                  ),
                                  child: Text(
                                    filtered[filteredIndex],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              );
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

  Future<StaffMember?> _showTechnicianPickerSheet(
    BuildContext context,
    List<StaffMember> technicians,
  ) {
    return showModalBottomSheet<StaffMember>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Technician',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Assign a staff member to this repair.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (technicians.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No staff members found.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
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
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  Icons.person_outline_rounded,
                                  color: AppColors.primary,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      staff.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
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
      _showMessage(
        e.response?.data?['message'] ?? 'Failed to reassign repair request',
      );
    } catch (e) {
      _showMessage('Failed to reassign repair request');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _hasWaitingForPartsDetails {
    final days = _repair['waitingForPartsDays'];
    final description =
        _repair['waitingForPartsDescription']?.toString().trim() ?? '';
    return days != null || description.isNotEmpty;
  }

  bool get _isCompleted => const {
    'completed',
    'collected',
  }.contains(_repair['status']?.toString().trim().toLowerCase());

  String get _technicianDisplayName {
    final direct = _repair['technicianName']?.toString().trim() ?? '';
    if (direct.isNotEmpty) return direct;

    final fallback = _repair['technician']?.toString().trim() ?? '';
    if (fallback.isNotEmpty) return fallback;

    final notes = _repair['shopkeeperNotes'];
    if (notes is List && notes.isNotEmpty) {
      final latest = notes.last;
      if (latest is Map) {
        final assigned = latest['assignedPerson']?.toString().trim() ?? '';
        if (assigned.isNotEmpty) return assigned;
      }
    }

    return 'Unassigned';
  }

  String get _customerName {
    final first = _repair['firstName']?.toString().trim() ?? '';
    final last = _repair['lastName']?.toString().trim() ?? '';
    final fullName = '$first $last'.trim();
    return fullName.isEmpty ? 'Customer' : fullName;
  }

  String get _customerPhone => _repair['phoneNumber']?.toString().trim() ?? '';

  String get _customerEmail => _repair['email']?.toString().trim() ?? '';

  String get _shopName {
    final repairShop = _repair['shopName']?.toString().trim() ?? '';
    if (repairShop.isNotEmpty) return repairShop;

    try {
      final profileCtrl = Get.find<ProfileController>();
      final profileShop = profileCtrl.shopName.trim();
      if (profileShop.isNotEmpty) return profileShop;
    } catch (_) {}

    return 'our repair shop';
  }

  String get _currencySymbol {
    try {
      if (Get.isRegistered<ProfileController>()) {
        final profileCtrl = Get.find<ProfileController>();
        final symbol = profileCtrl.currencySymbol.trim();
        if (symbol.isNotEmpty) return symbol;
      }
    } catch (_) {}

    final repairCurrency = _repair['currency']?.toString().trim() ?? '';
    if (repairCurrency.isNotEmpty) {
      const symbols = ProfileController.currencyOptions;
      if (symbols.containsKey(repairCurrency.toUpperCase())) {
        return symbols[repairCurrency.toUpperCase()]!;
      }
      return repairCurrency;
    }

    return '£';
  }

  String get _requestShortCode {
    final id = _repair['_id']?.toString() ?? '';
    if (id.isEmpty) return 'N/A';
    return id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
  }

  String _sanitizePhoneNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final hasLeadingPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return '';

    return hasLeadingPlus ? '+$digitsOnly' : digitsOnly;
  }

  String _buildCompletionMessage() {
    final feedback = _repair['technicianFeedback']?.toString().trim() ?? '';
    final price = (_repair['price'] as num?)?.toDouble() ?? 0;
    final priceText = price > 0
        ? '\nTotal bill: $_currencySymbol${price.toStringAsFixed(2)}.'
        : '';
    final feedbackText = feedback.isNotEmpty
        ? '\nTechnician note: $feedback'
        : '';

    return [
      'Hello $_customerName,',
      '',
      'Your ${_repair['deviceModel'] ?? 'device'} repair has been completed at $_shopName.',
      '',
      'Request ID: $_requestShortCode.$priceText$feedbackText',
      '',
      'Your device is ready for collection. Please contact us if you need any help.',
    ].join('\n');
  }

  Future<void> _launchUri(
    Uri uri, {
    required String successLabel,
    String? fallbackShareText,
  }) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && fallbackShareText != null) {
        await Share.share(fallbackShareText);
        _showMessage('Shared completion message');
        return;
      }
      if (!launched) {
        _showMessage('Unable to open $successLabel');
      }
    } catch (_) {
      if (fallbackShareText != null) {
        await Share.share(fallbackShareText);
        _showMessage('Shared completion message');
        return;
      }
      _showMessage('Unable to open $successLabel');
    }
  }

  Future<void> _sendCompletionOnWhatsApp() async {
    final phone = _sanitizePhoneNumber(_customerPhone);
    if (phone.isEmpty) {
      _showMessage('Customer phone number is missing');
      return;
    }

    await _launchUri(
      repairWhatsAppUri(phone, _buildCompletionMessage()),
      successLabel: 'WhatsApp',
      fallbackShareText: _buildCompletionMessage(),
    );
  }

  Future<void> _sendCompletionBySms() async {
    final phone = _sanitizePhoneNumber(_customerPhone);
    if (phone.isEmpty) {
      _showMessage('Customer phone number is missing');
      return;
    }

    await _launchUri(
      repairSmsUri(phone, _buildCompletionMessage()),
      successLabel: 'messages',
      fallbackShareText: _buildCompletionMessage(),
    );
  }

  Future<void> _sendCompletionByEmail() async {
    await _sendByEmail(
      _buildCompletionMessage(),
      subject: 'Your repair is complete - $_shopName',
    );
  }

  Future<void> _showCompletionContactSheet({bool autoOpened = false}) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  autoOpened ? 'Repair Completed' : 'Notify Customer',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  autoOpened
                      ? 'Choose how you want to notify the customer that the repair is done.'
                      : 'Send the completed-job update through WhatsApp, message, or email.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _contactActionChip(
                      label: 'WhatsApp',
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: _sendCompletionOnWhatsApp,
                    ),
                    _contactActionChip(
                      label: 'Message',
                      icon: Icons.sms_outlined,
                      onTap: _sendCompletionBySms,
                    ),
                    _contactActionChip(
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      onTap: _sendCompletionByEmail,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.fieldBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Text(
                    _buildCompletionMessage(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
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

  String _buildRejectionMessage(String reason) {
    final cleanReason = reason.trim();
    return 'Hello $_customerName, after checking your ${_repair['deviceModel'] ?? 'device'}, we are sorry that we could not complete the repair at $_shopName.'
        '${cleanReason.isNotEmpty ? '\nReason: $cleanReason' : ''}'
        '\nPlease contact us for the next best option or to collect the device. We are happy to help further.';
  }

  Future<void> _sendRejectionOnWhatsApp(String reason) async {
    final phone = _sanitizePhoneNumber(_customerPhone);
    if (phone.isEmpty) {
      _showMessage('Customer phone number is missing');
      return;
    }

    await _launchUri(
      repairWhatsAppUri(phone, _buildRejectionMessage(reason)),
      successLabel: 'WhatsApp',
      fallbackShareText: _buildRejectionMessage(reason),
    );
  }

  Future<void> _sendRejectionBySms(String reason) async {
    final phone = _sanitizePhoneNumber(_customerPhone);
    if (phone.isEmpty) {
      _showMessage('Customer phone number is missing');
      return;
    }

    await _launchUri(
      repairSmsUri(phone, _buildRejectionMessage(reason)),
      successLabel: 'messages',
      fallbackShareText: _buildRejectionMessage(reason),
    );
  }

  Future<void> _sendRejectionByEmail(String reason) async {
    await _sendByEmail(
      _buildRejectionMessage(reason),
      subject: 'Repair update for your device - $_shopName',
    );
  }

  Future<void> _showRejectedContactSheet(String reason) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Repair Rejected',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose how you want to send the apology and repair update.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _contactActionChip(
                      label: 'WhatsApp',
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => _sendRejectionOnWhatsApp(reason),
                    ),
                    _contactActionChip(
                      label: 'Message',
                      icon: Icons.sms_outlined,
                      onTap: () => _sendRejectionBySms(reason),
                    ),
                    _contactActionChip(
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                      onTap: () => _sendRejectionByEmail(reason),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.fieldBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Text(
                    _buildRejectionMessage(reason),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
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

  Future<void> _showRejectDialog() async {
    final reasonCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Repair',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 4,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Why could this repair not be completed?',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.fieldBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.fieldBorder),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      _showMessage('Please add a reason before rejecting the repair');
      return;
    }

    final id = _repair['_id']?.toString();
    if (id == null || id.isEmpty) return;

    setState(() => _isUpdating = true);
    try {
      final res = await _api.put(
        RepairRequestEndpoints.updateStatus(id),
        data: {'status': 'rejected'},
      );
      final data = res.data['data'];
      if (data is Map) {
        setState(() {
          _repair = Map<String, dynamic>.from(data);
          _repair['rejectionReason'] = reason;
        });
      } else {
        setState(() {
          _repair['status'] = 'rejected';
          _repair['rejectionReason'] = reason;
        });
      }
      _showMessage('Repair marked as Rejected');
      await _showRejectedContactSheet(reason);
    } on DioException catch (e) {
      _showMessage(e.response?.data?['message'] ?? 'Failed to reject repair');
    } catch (_) {
      _showMessage('Failed to reject repair');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _contactActionChip({
    required String label,
    required IconData icon,
    required Future<void> Function() onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          Navigator.of(context).maybePop();
          await onTap();
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
            title: 'Repair Request Details',
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, color: AppColors.textPrimary),
              color: AppColors.cardBackground,
              onSelected: (val) {
                if (val == 'receipt') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReceiptPage(repair: _repair)),
                  );
                } else if (val == 'status') {
                  _showStatusChangeModal();
                } else if (val == 'edit') {
                  _showEditJobDialog();
                } else if (val == 'add_issue') {
                  _showAddIssueDialog();
                } else if (val == 'add_photos') {
                  _showAddPhotosDialog();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Job')),
                const PopupMenuItem(value: 'add_issue', child: Text('Add Issue')),
                const PopupMenuItem(value: 'add_photos', child: Text('Add Photos')),
                const PopupMenuItem(value: 'status', child: Text('Change Status')),
                const PopupMenuItem(value: 'receipt', child: Text('Make a Receipt')),
              ],
            ),
          ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          _buildTopDeviceHeaderCard(),
                          const SizedBox(height: 16),
                          _buildCustomerDetailsWithShortcuts(),
                          const SizedBox(height: 16),
                          _buildQuickActionsBar(),
                          const SizedBox(height: 20),
                          _buildIssuesSection(),
                          const SizedBox(height: 20),
                          _buildEvidencePhotosSection(),
                          const SizedBox(height: 20),
                          TimelineWidget(steps: _buildTimelineSteps()),
                          if (_hasWaitingForPartsDetails) ...[
                            const SizedBox(height: 20),
                            _buildWaitingForPartsCard(),
                          ],
                          if (_isCompleted) ...[
                            const SizedBox(height: 20),
                            _buildCompletionContactCard(),
                          ],
                          if (_repair['status']?.toString() == 'rejected') ...[
                            const SizedBox(height: 20),
                            _buildRejectedStatusCard(),
                          ],
                          const SizedBox(height: 20),
                          _buildVerifyAndCompleteSection(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- NEW HEADER & CARDS MATCHING DEVELOPER NOTES 1/2 & 2/2 ---

  Widget _buildTopDeviceHeaderCard() {
    final status = _formatStatus(_repair['status']?.toString());
    final rawPrice = (_repair['price'] as num?)?.toDouble() ?? 0.0;
    final deviceModel = _repair['deviceModel']?.toString() ?? 'Device';
    final reqId = _repair['_id']?.toString() ?? '';
    final shortId = reqId.length > 8 ? reqId.substring(reqId.length - 8) : reqId;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Icon(
              Icons.phone_iphone_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        deviceModel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
                const SizedBox(height: 4),
                Text(
                  'Job #REP-$shortId',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Booked price ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '£${rawPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsWithShortcuts() {
    final phone = _customerPhone;
    final email = _customerEmail;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _customerName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Phone row with Call and SMS inline
          Row(
            children: [
              Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phone.isNotEmpty ? phone : 'No phone number',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (phone.isNotEmpty) ...[
                _buildSmallActionBtn(
                  icon: Icons.call,
                  label: 'Call',
                  color: const Color(0xFF10B981),
                  onTap: () => _launchUri(
                    Uri.parse('tel:$phone'),
                    successLabel: 'phone dialer',
                  ),
                ),
                const SizedBox(width: 6),
                _buildSmallActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'SMS',
                  color: const Color(0xFF10B981),
                  onTap: () => _sendBySms('Hello $_customerName, regarding your repair...'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Email row with Email action inline
          Row(
            children: [
              Icon(Icons.mail_outline_rounded, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  email.isNotEmpty ? email : 'No email address',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (email.isNotEmpty)
                _buildSmallActionBtn(
                  icon: Icons.email_outlined,
                  label: '',
                  color: const Color(0xFF10B981),
                  onTap: () => _sendByEmail(
                    'Hello $_customerName,\n\nRegarding your device repair ($deviceModelName)...',
                    subject: 'Update on your repair - $_shopName',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: label.isNotEmpty ? 10 : 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get deviceModelName => _repair['deviceModel']?.toString() ?? 'Device';

  Widget _buildQuickActionsBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickActionBtn(
            icon: Icons.edit_outlined,
            label: 'Edit job',
            onTap: _showEditJobDialog,
          ),
          const SizedBox(width: 8),
          _buildQuickActionBtn(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add issue',
            onTap: _showAddIssueDialog,
          ),
          const SizedBox(width: 8),
          _buildQuickActionBtn(
            icon: Icons.camera_alt_outlined,
            label: 'Add photos',
            onTap: _showAddPhotosDialog,
          ),
          const SizedBox(width: 8),
          _buildQuickActionBtn(
            icon: Icons.checklist_rounded,
            label: 'Status',
            onTap: _showStatusChangeModal,
          ),
          const SizedBox(width: 8),
          _buildQuickActionBtn(
            icon: Icons.receipt_long_rounded,
            label: 'Receipt',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReceiptPage(repair: _repair)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ISSUES CHECKLIST WITH FIXED AND TESTED TOGGLES (DEVELOPER NOTE 2/2) ---

  List<String> get _parsedIssues {
    final rawDesc = _repair['description']?.toString() ?? '';
    final lines = rawDesc
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return lines.isEmpty ? ['No issues listed'] : lines;
  }

  final Map<int, bool> _fixedIssues = {};
  final Map<int, bool> _testedIssues = {};
  bool _confirmChecklistAllFixed = false;

  Widget _buildIssuesSection() {
    final issues = _parsedIssues;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Issues (${issues.length})',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: _showAddIssueDialog,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Add issue',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...issues.asMap().entries.map((entry) {
            final idx = entry.key;
            final issue = entry.value;
            final isFixed = _fixedIssues[idx] ?? false;
            final isTested = _testedIssues[idx] ?? false;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.fieldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditSingleIssueDialog(idx, issue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Fixed checkbox
                      InkWell(
                        onTap: () {
                          setState(() {
                            _fixedIssues[idx] = !isFixed;
                          });
                        },
                        child: Row(
                          children: [
                            Checkbox(
                              value: isFixed,
                              activeColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) {
                                setState(() {
                                  _fixedIssues[idx] = v ?? false;
                                });
                              },
                            ),
                            Text(
                              'Fixed',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tested checkbox
                      InkWell(
                        onTap: () {
                          setState(() {
                            _testedIssues[idx] = !isTested;
                          });
                        },
                        child: Row(
                          children: [
                            Checkbox(
                              value: isTested,
                              activeColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) {
                                setState(() {
                                  _testedIssues[idx] = v ?? false;
                                });
                              },
                            ),
                            Text(
                              'Tested',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- EVIDENCE PHOTOS SECTION (BEFORE / DURING / AFTER) ---

  List<String> get _evidenceImages {
    final List<String> list = [];
    final direct = _repair['images'];
    if (direct is List) {
      for (final item in direct) {
        if (item is Map && item['url'] != null) {
          list.add(item['url'].toString());
        } else if (item is String) {
          list.add(item);
        }
      }
    }
    final notes = _repair['shopkeeperNotes'];
    if (notes is List) {
      for (final n in notes) {
        if (n is Map && n['images'] is List) {
          for (final img in (n['images'] as List)) {
            if (img is Map && img['url'] != null) {
              list.add(img['url'].toString());
            }
          }
        }
      }
    }
    return list;
  }

  Widget _buildEvidencePhotosSection() {
    final images = _evidenceImages;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Job evidence',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: _showAddPhotosDialog,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Upload',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (images.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final label = i == 0
                      ? 'Before'
                      : i == 1
                          ? 'During'
                          : 'After';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          images[i],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.fieldBackground,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppColors.fieldBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.photo_outlined, color: AppColors.textSecondary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    'No photos attached yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAndUploadPhoto(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Take photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.fieldBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickAndUploadPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Upload'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.fieldBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Technician can add evidence at any time and link photos to an issue.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // --- COMPLETE REPAIR FLOW WITH VERIFICATION (DEVELOPER NOTE 2/2) ---

  Widget _buildVerifyAndCompleteSection() {
    final issues = _parsedIssues;
    final totalIssues = issues.length;
    int verifiedCount = 0;
    for (int i = 0; i < totalIssues; i++) {
      if ((_fixedIssues[i] ?? false) && (_testedIssues[i] ?? false)) {
        verifiedCount++;
      }
    }
    final allVerified = totalIssues > 0 && verifiedCount == totalIssues;
    final canComplete = allVerified && _confirmChecklistAllFixed;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verify & Complete',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$verifiedCount of $totalIssues issues verified',
                style: TextStyle(
                  color: allVerified ? const Color(0xFF10B981) : AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                'Technician: $_technicianDisplayName',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              setState(() {
                _confirmChecklistAllFixed = !_confirmChecklistAllFixed;
              });
            },
            child: Row(
              children: [
                Checkbox(
                  value: _confirmChecklistAllFixed,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() {
                      _confirmChecklistAllFixed = v ?? false;
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'I confirm all issues are fixed and tested',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canComplete ? () => _updateStatus('completed') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.fieldBackground,
                disabledForegroundColor: AppColors.textSecondary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Complete repair',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (!canComplete) ...[
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Finish all issue checks and check confirmation before completion.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- ACTIONS: EDIT JOB, ADD ISSUE, ADD PHOTOS, STATUS CHANGE ---

  Future<void> _showEditJobDialog() async {
    final devCtrl = TextEditingController(text: _repair['deviceModel']?.toString() ?? '');
    final imeiCtrl = TextEditingController(text: _repair['IMEINumber']?.toString() ?? '');
    final priceCtrl = TextEditingController(
      text: ((_repair['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
    );

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Job Details',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: devCtrl,
              decoration: const InputDecoration(labelText: 'Device Model'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: imeiCtrl,
              decoration: const InputDecoration(labelText: 'IMEI / Serial'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Booked Price (£)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (updated == true) {
      final id = _repair['_id']?.toString() ?? '';
      final parsedPrice = double.tryParse(priceCtrl.text.trim()) ?? 0;
      setState(() {
        _repair['deviceModel'] = devCtrl.text.trim();
        _repair['IMEINumber'] = imeiCtrl.text.trim();
        _repair['price'] = parsedPrice;
      });
      // Try updating through backend reassign / update endpoint
      try {
        await _api.put(
          RepairRequestEndpoints.reassign(id),
          data: {
            'deviceModel': devCtrl.text.trim(),
            'IMEINumber': imeiCtrl.text.trim(),
            'price': parsedPrice,
          },
        );
      } catch (_) {}
      _showMessage('Job details updated');
    }
  }

  Future<void> _showAddIssueDialog() async {
    final issueCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add New Issue',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: issueCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Describe new issue...',
            filled: true,
            fillColor: AppColors.fieldBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (issueCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Add Issue'),
          ),
        ],
      ),
    );

    if (added == true && issueCtrl.text.trim().isNotEmpty) {
      final newDesc = [
        ..._parsedIssues.where((s) => s != 'No issues listed'),
        issueCtrl.text.trim(),
      ].join('\n');

      final id = _repair['_id']?.toString() ?? '';
      setState(() => _repair['description'] = newDesc);

      try {
        await _api.put(
          RepairRequestEndpoints.reassign(id),
          data: {'description': newDesc},
        );
      } catch (_) {}
      _showMessage('New issue added to repair job');
    }
  }

  Future<void> _showEditSingleIssueDialog(int index, String currentText) async {
    final editCtrl = TextEditingController(text: currentText);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Issue',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: editCtrl,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.fieldBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && editCtrl.text.trim().isNotEmpty) {
      final issues = List<String>.from(_parsedIssues);
      issues[index] = editCtrl.text.trim();
      final newDesc = issues.join('\n');
      final id = _repair['_id']?.toString() ?? '';
      setState(() => _repair['description'] = newDesc);
      try {
        await _api.put(
          RepairRequestEndpoints.reassign(id),
          data: {'description': newDesc},
        );
      } catch (_) {}
      _showMessage('Issue updated');
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    final id = _repair['_id']?.toString() ?? '';
    setState(() => _isUpdating = true);

    try {
      final formData = FormData();
      formData.fields.add(const MapEntry('message', 'Attached evidence photo'));
      formData.fields.add(const MapEntry('cost', '0'));
      formData.fields.add(const MapEntry('estimatedDays', '0'));
      formData.fields.add(MapEntry('assignedPerson', _technicianDisplayName));
      formData.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(
            picked.path,
            filename: picked.path.split('/').last,
          ),
        ),
      );

      final res = await _api.put(
        RepairRequestEndpoints.addNote(id),
        data: formData,
      );
      final data = res.data['data'];
      if (data is Map) {
        setState(() => _repair = Map<String, dynamic>.from(data));
      } else {
        await _refreshRepair();
      }
      _showMessage('Photo attached to job successfully');
    } catch (_) {
      _showMessage('Failed to upload photo');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showAddPhotosDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Evidence Photos',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Take Photo with Camera', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Upload from Gallery', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showStatusChangeModal() async {
    final statuses = [
      ('order-assigned', 'Order Assigned'),
      ('diagnosing', 'Diagnosing Device'),
      ('repairing', 'Repairing Device'),
      ('waiting-for-parts', 'Waiting for Parts'),
      ('completed', 'Completed'),
      ('rejected', 'Rejected'),
      ('reassigned', 'Reassigned'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Repair Status',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...statuses.map(
                (s) => ListTile(
                  title: Text(s.$2, style: TextStyle(color: AppColors.textPrimary)),
                  trailing: _repair['status'] == s.$1
                      ? Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    if (s.$1 == 'waiting-for-parts') {
                      _showWaitingForPartsDialog();
                    } else if (s.$1 == 'rejected') {
                      _showRejectDialog();
                    } else if (s.$1 == 'reassigned') {
                      _showReassignDialog();
                    } else {
                      _updateStatus(s.$1);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TimelineStep> _buildTimelineSteps() =>
      buildRepairTimeline(_repair['status']?.toString() ?? '');



  Widget _buildWaitingForPartsCard() {
    final days = _repair['waitingForPartsDays']?.toString() ?? 'N/A';
    final description =
        _repair['waitingForPartsDescription']?.toString().trim() ??
        'No details provided.';

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Waiting for Parts',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InfoField(label: 'ESTIMATED DAYS', value: days),
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
              description,
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

  Widget _buildCompletionContactCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notify Customer',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Send the completed repair update by WhatsApp, message, or email.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showCompletionContactSheet(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Open Contact Options',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedStatusCard() {
    final reason =
        _repair['rejectionReason']?.toString().trim() ??
        'Repair could not be completed.';

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rejected Repair',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            reason,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showRejectedContactSheet(reason),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Send Sorry Message',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
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
      'collected' => 'Collected',
      'unable-to-repair' => 'Unable to Repair',
      'inReview' => 'In Review',
      'start-work' => 'Start Work',
      'quote_sent' || 'quote-sent' => 'Quote Sent',
      'waiting-for-parts' => 'Waiting for Parts',
      'diagnosing' => 'Diagnosing',
      'repairing' => 'Repairing',
      'order-assigned' => 'Order Assigned',
      'reassigned' => 'Reassigned',
      null || '' => 'In Progress',
      _ => status,
    };
  }
}
