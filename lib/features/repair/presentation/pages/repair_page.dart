import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/more_menu_button.dart';
import '../../../../core/utils/sound_effects.dart';
import '../../../customer/data/repositories/customer_repository_impl.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';
import '../../../staff/data/repositories/staff_repository_impl.dart';
import '../../../staff/domain/entities/staff_member.dart';
import '../../../staff/presentation/pages/staff_page.dart';
import '../controller/repair_data.dart';
import '../utils/repair_request_formatter.dart';
import '../widgets/pending_repair_card.dart';
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
  final Set<String> _nudgingIds = {};

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

  List<RepairItem> get _pendingRepairs =>
      _repairs.where((item) => item.isActive).toList();

  String? _repairId(RepairItem item) => item.raw['_id']?.toString();

  Future<void> _nudgeTechnician(RepairItem item) async {
    final id = _repairId(item);
    if (id == null) return;

    setState(() => _nudgingIds.add(id));
    try {
      await _api.post(RepairRequestEndpoints.nudge(id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder sent to ${item.raw['technicianName'] ?? 'technician'}',
          ),
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final message = e.response?.statusCode == 404
          ? 'Nudge feature isn\'t available yet'
          : (e.response?.data?['message'] ?? 'Failed to send reminder');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send reminder')));
    } finally {
      if (mounted) setState(() => _nudgingIds.remove(id));
    }
  }

  Future<void> _fetchRepairs() async {
    if (!mounted) return;
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
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _errorMessage =
            e.response?.data?['message'] ?? 'Failed to load repair requests';
      });
    } catch (e) {
      if (!mounted) return;
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

      final res = await _api.get(
        RepairRequestEndpoints.userDescriptions(userId),
      );
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

  Future<List<Customer>> _fetchCustomerOptions() async {
    try {
      final profileCtrl = Get.find<ProfileController>();
      var userId = profileCtrl.userId;
      if (userId.isEmpty) {
        await profileCtrl.fetchProfile();
        userId = profileCtrl.userId;
      }
      if (userId.isEmpty) return [];
      return await CustomerRepositoryImpl(_api).getCustomers(userId);
    } catch (_) {
      return [];
    }
  }

  // Lets a shopkeeper/technician scan a device's IMEI barcode or a repair
  // ticket's QR code to jump straight to that request's status/warranty
  // details instead of hunting through the list manually.
  Future<void> _scanToTrack() async {
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    final code = scanned?.trim();
    if (code == null || code.isEmpty || !mounted) return;

    final localMatch = _repairs.firstWhere(
      (item) => item.imei == code || _repairId(item) == code,
      orElse: () => RepairItem(
        name: '',
        brand: '',
        issueLabel: '',
        issueDesc: '',
        date: '',
        status: '',
      ),
    );

    if (localMatch.raw.isNotEmpty) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RepairRequestDetailsPage(repair: localMatch.raw),
        ),
      );
      return;
    }

    // Not in the currently loaded page of results — try it as a request id.
    try {
      final res = await _api.get(RepairRequestEndpoints.byId(code));
      final data = res.data['data'];
      if (data is Map && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RepairRequestDetailsPage(
              repair: Map<String, dynamic>.from(data),
            ),
          ),
        );
        return;
      }
    } catch (_) {
      // fall through to not-found message
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No repair request found for this code')),
    );
  }

  Future<void> _showCreateRepairSheet() async {
    final deviceCtrl = TextEditingController();
    final imeiCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final firstNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String? selectedProblem;
    StaffMember? selectedTechnician;
    Customer? selectedCustomer;

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
                    _sheetField(
                      imeiCtrl,
                      'IMEI Number (Optional)',
                      'Enter or scan IMEI',
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () async {
                          final scanned = await Navigator.push<String>(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => const BarcodeScannerPage(),
                            ),
                          );
                          if (scanned != null && scanned.trim().isNotEmpty) {
                            setSheetState(() => imeiCtrl.text = scanned.trim());
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    _sheetSelectField(
                      label: 'Select Problem',
                      value: selectedProblem,
                      placeholder: 'Search or select a previous problem',
                      onTap: () async {
                        final choice = await _showSearchableProblemSheet(
                          ctx,
                          previousProblems,
                        );
                        if (choice != null) {
                          setSheetState(() {
                            selectedProblem = choice;
                            if (descCtrl.text.trim().isEmpty) {
                              descCtrl.text = choice;
                            }
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
                        (staff) =>
                            setSheetState(() => selectedTechnician = staff),
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
                    _sheetSelectField(
                      label: 'Customer',
                      value: selectedCustomer == null
                          ? null
                          : (selectedCustomer!.fullName.isEmpty
                                ? selectedCustomer!.email
                                : selectedCustomer!.fullName),
                      placeholder: 'Select existing customer (optional)',
                      onTap: () => _openCustomerPicker(ctx, (customer) {
                        setSheetState(() {
                          selectedCustomer = customer;
                          if (customer != null) {
                            firstNameCtrl.text = customer.fullName;
                            emailCtrl.text = customer.email;
                            phoneCtrl.text = customer.phone;
                          }
                        });
                      }),
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
                                      if (imeiCtrl.text.trim().isNotEmpty)
                                        'IMEINumber': imeiCtrl.text.trim(),
                                      'description': descCtrl.text.trim(),
                                      'firstName': firstNameCtrl.text.trim(),
                                      'email': emailCtrl.text.trim(),
                                      'phoneNumber': phoneCtrl.text.trim(),
                                      'price':
                                          double.tryParse(
                                            priceCtrl.text.trim(),
                                          ) ??
                                          0,
                                      if (selectedTechnician != null)
                                        'technicianId': selectedTechnician!.id,
                                      if (selectedTechnician != null)
                                        'technicianName':
                                            selectedTechnician!.fullName,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Repair order booked successfully!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        suffixIcon: suffixIcon,
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
          floatingLabelStyle: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
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

  Future<String?> _showSearchableProblemSheet(
    BuildContext context,
    List<String> problems,
  ) async {
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
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Select Problem',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reuse a problem you\'ve logged before, or type to search.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: AppColors.isDark ? 0.6 : 0.72,
                        ),
                        width: 1.2,
                      ),
                    ),
                    child: TextField(
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
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: problems.isEmpty && customProblem.isEmpty
                        ? _buildEmptyProblemState()
                        : filtered.isEmpty && customProblem.isEmpty
                        ? _buildEmptyProblemState(
                            message: 'No matching problems found.',
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
                                return _buildProblemTile(
                                  'Use "$customProblem"',
                                  icon: Icons.edit_note_rounded,
                                  onTap: () =>
                                      Navigator.pop(sheetCtx, customProblem),
                                );
                              }
                              final filteredIndex =
                                  (!hasExactCustomMatch &&
                                      customProblem.isNotEmpty)
                                  ? index - 1
                                  : index;
                              final item = filtered[filteredIndex];
                              return _buildProblemTile(
                                item,
                                onTap: () => Navigator.pop(sheetCtx, item),
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

  Widget _buildProblemTile(
    String label, {
    required VoidCallback onTap,
    IconData icon = Icons.history_rounded,
  }) {
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
            Icon(icon, color: AppColors.textSecondary, size: 18),
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

  Widget _buildEmptyProblemState({
    String message = 'No previous problems logged yet.',
  }) {
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
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCustomerPicker(
    BuildContext ctx,
    void Function(Customer?) onSelect,
  ) async {
    final customers = await _fetchCustomerOptions();
    if (!ctx.mounted) return;
    final pick = await _showCustomerSheet(ctx, customers);
    if (!ctx.mounted || pick == null) return;
    if (pick.openCustomerPage) {
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const CustomerPage()),
      );
      if (ctx.mounted) await _openCustomerPicker(ctx, onSelect);
      return;
    }
    onSelect(pick.customer);
  }

  Future<_CustomerPick?> _showCustomerSheet(
    BuildContext context,
    List<Customer> customers,
  ) {
    final searchCtrl = TextEditingController();
    return showModalBottomSheet<_CustomerPick>(
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
                ? customers
                : customers.where((customer) {
                    final haystack = [
                      customer.fullName,
                      customer.phone,
                      customer.email,
                    ].join(' ').toLowerCase();
                    return haystack.contains(query);
                  }).toList();

            return SafeArea(
              top: false,
              child: Padding(
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.fieldBorder,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Customer',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Search by customer name, phone, or email.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.fieldBackground,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: AppColors.primary.withValues(
                            alpha: AppColors.isDark ? 0.6 : 0.72,
                          ),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: searchCtrl,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search customer name or phone',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(sheetCtx).size.height * 0.5,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (customers.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  'No saved customers yet.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else if (filtered.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  'No customers matched your search.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else
                              ...filtered.map(
                                (customer) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildTechnicianTile(
                                    sheetCtx,
                                    icon: Icons.person_outline_rounded,
                                    title: customer.fullName.isEmpty
                                        ? customer.email
                                        : customer.fullName,
                                    subtitle: customer.phone.isEmpty
                                        ? customer.email
                                        : customer.phone,
                                    onTap: () => Navigator.pop(
                                      sheetCtx,
                                      _CustomerPick(customer),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(
                        sheetCtx,
                        const _CustomerPick(null, openCustomerPage: true),
                      ),
                      icon: Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      label: Text(
                        'Add Customer',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
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
  }

  Future<void> _openTechnicianPicker(
    BuildContext ctx,
    void Function(StaffMember?) onSelect,
  ) async {
    final technicians = await _fetchTechnicianOptions();
    if (!ctx.mounted) return;
    final pick = await _showTechnicianSheet(ctx, technicians);
    if (!ctx.mounted || pick == null) return;
    if (pick.openStaffPage) {
      await Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const StaffPage()),
      );
      if (ctx.mounted) await _openTechnicianPicker(ctx, onSelect);
      return;
    }
    onSelect(pick.staff);
  }

  Future<_TechnicianPick?> _showTechnicianSheet(
    BuildContext context,
    List<StaffMember> technicians,
  ) {
    return showModalBottomSheet<_TechnicianPick>(
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
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
                const SizedBox(height: 18),
                if (technicians.isEmpty)
                  _buildEmptyTechnicianState(sheetCtx)
                else ...[
                  _buildTechnicianTile(
                    sheetCtx,
                    icon: Icons.person_off_outlined,
                    title: 'Unassigned',
                    subtitle: 'No technician assigned yet',
                    onTap: () =>
                        Navigator.pop(sheetCtx, const _TechnicianPick(null)),
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
                        onTap: () =>
                            Navigator.pop(sheetCtx, _TechnicianPick(staff)),
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
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
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
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_2_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No staff members yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a staff member to assign repairs to a technician.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(
              sheetCtx,
              const _TechnicianPick(null, openStaffPage: true),
            ),
            icon: Icon(
              Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
              size: 16,
            ),
            label: Text(
              'Add Staff Member',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _scanToTrack,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                MoreMenuButton(),
              ],
            ),
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

    final completed = _repairs.where((item) => item.isCompleted).length;
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.navigation_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Use the bottom navigation bar to switch back to the main menu without closing the app.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
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
                  if (_pendingRepairs.isNotEmpty) ...[
                    _buildPendingSectionHeader(),
                    const SizedBox(height: 12),
                    ..._pendingRepairs.map(
                      (item) => PendingRepairCard(
                        item: item,
                        isNudging: _nudgingIds.contains(_repairId(item)),
                        onNudge: () => _nudgeTechnician(item),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RepairRequestDetailsPage(repair: item.raw),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
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

  Widget _buildPendingSectionHeader() {
    return Row(
      children: [
        Text(
          'Pending Repairs',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE8920A).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_pendingRepairs.length}',
            style: const TextStyle(
              color: Color(0xFFE8920A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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

class _CustomerPick {
  final Customer? customer;
  final bool openCustomerPage;

  const _CustomerPick(this.customer, {this.openCustomerPage = false});
}
