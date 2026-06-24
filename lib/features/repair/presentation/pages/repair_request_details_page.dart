import 'package:flutter/material.dart';
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

class RepairRequestDetailsPage extends StatelessWidget {
  final Map<String, dynamic> repair;

  const RepairRequestDetailsPage({super.key, this.repair = const {}});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Repair Request Details'),
          Expanded(
            child: SingleChildScrollView(
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
                      MaterialPageRoute(builder: (_) => ReceiptPage()),
                    ),
                  ),
                  SizedBox(height: 20),
                  TimelineWidget(steps: repairTimeline),
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

  Widget _buildDeviceCard() {
    final status = _formatStatus(repair['status']?.toString());
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
                        repair['deviceModel']?.toString() ?? 'Unknown device',
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
              repair['description']?.toString() ?? 'No description provided',
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
            value: '#${repair['_id']?.toString() ?? 'N/A'}',
          ),
          SizedBox(height: 12),
          InfoField(
            label: 'SUBMITTED',
            value: _formatDateTime(repair['createdAt']?.toString()),
          ),
          SizedBox(height: 12),
          InfoField(label: 'SHOP', value: 'Your Shop'),
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
                  'Order Assigned',
                  Color(0xFF8B1A1A),
                  Color(0xFFFF6B6B),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  'Diagnosing Device',
                  AppColors.fieldBackground,
                  AppColors.primary,
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
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  'Waiting for Parts',
                  Color(0xFF0D1A2E),
                  Color(0xFF4DB8FF),
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
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CheckoutPage()),
                  ),
                  child: _actionBtn(
                    'Check Out',
                    AppColors.fieldBackground,
                    AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color bg, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
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
    );
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
            value: repair['firstName']?.toString() ?? '',
          ),
          SizedBox(height: 12),
          InfoField(
            label: 'EMAIL ADDRESS',
            value: repair['email']?.toString() ?? '',
          ),
          SizedBox(height: 12),
          InfoField(
            label: 'PHONE NUMBER',
            value: repair['phoneNumber']?.toString() ?? '',
          ),
        ],
      ),
    );
  }

  String _formatStatus(String? status) {
    return switch (status) {
      'completed' => 'Completed',
      'rejected' => 'Rejected',
      null || '' => 'In Progress',
      _ => 'In Progress',
    };
  }

  String _formatDateTime(String? value) {
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
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${months[local.month - 1]} ${local.day.toString().padLeft(2, '0')}, ${local.year} · $hour:$minute $period';
  }
}
