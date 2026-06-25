import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_outlined_button.dart';
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
      final res = await _api.patch(
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
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 14),
                        _buildDeviceCard(),
                        SizedBox(height: 12),
                        _buildInfoCard(),
                        SizedBox(height: 14),
                        AppOutlinedButton(
                          label: 'Make a Receipt',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReceiptPage(repair: _repair),
                            ),
                          ),
                        ),
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

  Widget _buildDeviceCard() {
    final status = _formatStatus(_repair['status']?.toString());
    return AppCard(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoField(
                    label: 'DEVICE INFORMATION',
                    value:
                        _repair['deviceModel']?.toString() ?? 'Unknown device',
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(8),
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

  Widget _buildInfoCard() {
    return AppCard(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoField(
            label: 'REQUEST ID',
            value: '#${_repair['_id']?.toString() ?? 'N/A'}',
          ),
          SizedBox(height: 12),
          InfoField(
            label: 'SUBMITTED',
            value: _formatDateTime(_repair['createdAt']?.toString()),
          ),
          SizedBox(height: 12),
          InfoField(
            label: 'SHOP',
            value: _repair['shopName']?.toString() ?? 'Your Shop',
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
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
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  'In Progress',
                  Color(0xFF8B1A1A),
                  Color(0xFFFF6B6B),
                  onTap: () => _updateStatus('inProgress'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  'Diagnosing Device',
                  AppColors.fieldBackground,
                  AppColors.primary,
                  onTap: () => _updateStatus('diagnosing'),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  'Repairing Device',
                  Color(0xFF2A1A00),
                  Color(0xFFFFA500),
                  onTap: () => _updateStatus('repairing'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  'Waiting for Parts',
                  Color(0xFF0D1A2E),
                  Color(0xFF4DB8FF),
                  onTap: () => _updateStatus('waiting-for-parts'),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  'Completed',
                  AppColors.fieldBackground,
                  AppColors.primary,
                  onTap: () => _updateStatus('completed'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  'Check Out',
                  AppColors.fieldBackground,
                  AppColors.primary,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CheckoutPage(repair: _repair),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    Color bg,
    Color textColor, {
    VoidCallback? onTap,
  }) {
    final isCurrentStatus =
        _formatStatus(_repair['status']?.toString()) == label ||
        _repair['status']?.toString() == _statusKey(label);

    return GestureDetector(
      onTap: _isUpdating ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isCurrentStatus ? AppColors.primary.withValues(alpha: 0.2) : bg,
          borderRadius: BorderRadius.circular(50),
          border: isCurrentStatus
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  String _statusKey(String label) {
    switch (label) {
      case 'In Progress':
        return 'inProgress';
      case 'Diagnosing Device':
        return 'diagnosing';
      case 'Repairing Device':
        return 'repairing';
      case 'Waiting for Parts':
        return 'waiting-for-parts';
      case 'Completed':
        return 'completed';
      default:
        return '';
    }
  }

  Widget _buildCustomerDetails() {
    return AppCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoField(label: 'CUSTOMER DETAILS', value: ''),
          SizedBox(height: 14),
          InfoField(
            label: 'NAME',
            value: _repair['firstName']?.toString() ?? '',
          ),
          SizedBox(height: 12),
          InfoField(
            label: 'EMAIL ADDRESS',
            value: _repair['email']?.toString() ?? '',
          ),
          SizedBox(height: 12),
          InfoField(
            label: 'PHONE NUMBER',
            value: _repair['phoneNumber']?.toString() ?? '',
          ),
        ],
      ),
    );
  }

  String _formatStatus(String? status) {
    return switch (status) {
      'completed' => 'Completed',
      'rejected' => 'Rejected',
      'inProgress' || 'order-assigned' || 'quote_sent' || 'approved' || 'start-work' || 'inReview' => 'In Progress',
      'diagnosing' => 'Diagnosing Device',
      'repairing' => 'Repairing Device',
      'waiting-for-parts' => 'Waiting for Parts',
      null || '' => 'In Progress',
      _ => 'In Progress',
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
