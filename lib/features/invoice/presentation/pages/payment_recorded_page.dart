import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_success_tick_animation.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../profile/presentation/controller/profile_controller.dart';

class PaymentRecordedPage extends StatelessWidget {
  final File receiptFile;
  final String paymentMethod;
  final double amountPaid;
  final double cashRemaining;

  const PaymentRecordedPage({
    super.key,
    required this.receiptFile,
    required this.paymentMethod,
    required this.amountPaid,
    required this.cashRemaining,
  });

  String get _currencySymbol => Get.find<ProfileController>().currencySymbol;

  Future<void> _shareReceipt() async {
    await Share.shareXFiles(
      [XFile(receiptFile.path)],
      text:
          'Purchase receipt — $_currencySymbol${amountPaid.toStringAsFixed(2)} paid.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            children: [
              const AppSuccessTickAnimation(size: 150),
              const SizedBox(height: 20),
              Text(
                'Payment Recorded Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Receipt is ready to share with the customer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT SUMMARY',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      Icons.account_balance_outlined,
                      'Payment Method',
                      paymentMethod,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      Icons.payments_outlined,
                      'Amount Paid',
                      '$_currencySymbol${amountPaid.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      Icons.send_outlined,
                      'Receipt Status',
                      'Ready to Share',
                      valueColor: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      Icons.account_balance_wallet_outlined,
                      'Cash Remaining',
                      '$_currencySymbol${cashRemaining.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _shareReceipt,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Send Receipt Again'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _shareReceipt,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.fieldBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Download Receipt'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                      ..pop()
                      ..pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surfaceForeground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
