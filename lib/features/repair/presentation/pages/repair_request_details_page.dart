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
  const RepairRequestDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Repair Request Details'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  _buildDeviceCard(),
                  const SizedBox(height: 12),
                  _buildInfoCard(),
                  const SizedBox(height: 14),
                  AppOutlinedButton(label: 'Make a Receipt', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceiptPage()))),
                  const SizedBox(height: 20),
                  const TimelineWidget(steps: repairTimeline),
                  const SizedBox(height: 20),
                  _buildActions(context),
                  const SizedBox(height: 20),
                  _buildCustomerDetails(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard() {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoField(label: 'DEVICE INFORMATION', value: 'iPhone 14 Pro'),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(20)),
                child: const Text('In Progress', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF0B1520), borderRadius: BorderRadius.circular(8)),
            child: const Text('BROKEN SCREEN, PLUS BACK NEEDS TO CHANGE...', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return const AppCard(
      padding: EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoField(label: 'REQUEST ID', value: '#6A281FA64AB4CD6B2D3D6031'),
          SizedBox(height: 12),
          InfoField(label: 'SUBMITTED', value: 'Jun 09, 2026 · 07:53 PM'),
          SizedBox(height: 12),
          InfoField(label: 'SHOP', value: 'Your Shop'),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _actionBtn('Order Assigned', const Color(0xFF8B1A1A), const Color(0xFFFF6B6B))),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('Diagnosing Device', const Color(0xFF0D2A1A), AppColors.primary)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _actionBtn('Repairing Device', const Color(0xFF2A1A00), const Color(0xFFFFA500))),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('Waiting for Parts', const Color(0xFF0D1A2E), const Color(0xFF4DB8FF))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _actionBtn('Completed', const Color(0xFF0D2A1A), AppColors.primary)),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutPage())),
                child: _actionBtn('Check Out', const Color(0xFF0D2A1A), AppColors.primary),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(50)),
      child: Center(child: Text(label, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600))),
    );
  }

  Widget _buildCustomerDetails() {
    return const AppCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoField(label: 'CUSTOMER DETAILS', value: ''),
          SizedBox(height: 14),
          InfoField(label: 'NAME', value: 'John'),
          SizedBox(height: 12),
          InfoField(label: 'EMAIL ADDRESS', value: 'john@gmai.com'),
          SizedBox(height: 12),
          InfoField(label: 'PHONE NUMBER', value: '+1 266 625 515'),
        ],
      ),
    );
  }
}
