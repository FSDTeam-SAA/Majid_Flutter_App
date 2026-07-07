import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/info_field.dart';
import '../controller/repair_data.dart';
import '../widgets/timeline_widget.dart';
import 'checkout_page.dart';
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
      'diagnosing',
      'quote_sent',
      'repairing',
      'waiting-for-parts',
      'completed',
      'checkout',
    ];

    var currentIndex = statusOrder.indexOf(status);
    if (currentIndex < 0 && status == 'approved') currentIndex = 1;
    if (currentIndex < 0 && status == 'start-work') currentIndex = 4;
    if (currentIndex < 0 && status == 'inReview') currentIndex = 2;

    TimelineStatus stepStatus(int index) {
      if (currentIndex < 0) return TimelineStatus.pending;
      if (index < currentIndex) return TimelineStatus.done;
      if (index == currentIndex) return TimelineStatus.inProgress;
      return TimelineStatus.pending;
    }

    return [
      TimelineStep('Order Booked', 'Your order has been successfully created', stepStatus(0)),
      TimelineStep('Order Assigned', 'A technician has been assigned', stepStatus(1)),
      TimelineStep('Diagnosing Started', 'Technician is diagnosing the issue', stepStatus(2)),
      TimelineStep('Quote Sent', 'A quote has been sent for the repair', stepStatus(3)),
      TimelineStep('Repairing Started', 'Device is being repaired', stepStatus(4)),
      TimelineStep('Waiting for Parts', 'Repair is paused until parts arrive', stepStatus(5)),
      TimelineStep('Repair Complete', 'Repair has been successfully completed', stepStatus(6)),
      TimelineStep('Checkout', 'Repair has been successfully completed', stepStatus(7)),
    ];
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
        label: 'Check Out',
        tone: _RepairActionTone.checkOut,
        activeStatuses: const {'checkout'},
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CheckoutPage(repair: _repair)),
        ),
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
      _RepairActionTone.checkOut => (
        const Color(0xFF10271C),
        const Color(0xFF0B1F16),
        const Color(0xFF2B5635),
        const Color(0xFF85FF79),
        const Color(0xFF85FF79),
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
      _RepairActionTone.checkOut => (
        const Color(0xFFFF2B31),
        const Color(0xFFFF2B31),
        const Color(0xFFFF6870),
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
  checkOut,
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
