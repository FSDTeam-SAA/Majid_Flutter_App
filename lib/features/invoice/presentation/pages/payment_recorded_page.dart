import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_success_tick_animation.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../profile/presentation/controller/profile_controller.dart';

class PaymentRecordedPage extends StatefulWidget {
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

  @override
  State<PaymentRecordedPage> createState() => _PaymentRecordedPageState();
}

class _PaymentRecordedPageState extends State<PaymentRecordedPage> {
  final GlobalKey _shareKey = GlobalKey();
  bool _didPromptShare = false;

  String get _currencySymbol => Get.find<ProfileController>().currencySymbol;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPromptShare) return;
    _didPromptShare = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showShareOptions();
    });
  }

  Future<void> _shareReceipt({String? subjectHint}) async {
    await Share.shareXFiles(
      [XFile(widget.receiptFile.path)],
      text:
          'Purchase receipt - $_currencySymbol${widget.amountPaid.toStringAsFixed(2)} paid.',
      subject: subjectHint,
      sharePositionOrigin: _shareOriginFor(_shareKey),
    );
  }

  Future<void> _showShareOptions() async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Share Receipt',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how you want to share or print the receipt.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 18),
                _ShareOptionTile(
                  icon: Icons.message_outlined,
                  title: 'Message',
                  subtitle: 'Open the system share sheet for SMS or chat apps',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareReceipt(subjectHint: 'Receipt via message');
                  },
                ),
                const SizedBox(height: 10),
                _ShareOptionTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  subtitle:
                      'Open Mail and other email apps from the share sheet',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareReceipt(subjectHint: 'Receipt via email');
                  },
                ),
                const SizedBox(height: 10),
                _ShareOptionTile(
                  icon: Icons.print_outlined,
                  title: 'Print Paper',
                  subtitle:
                      'Use the system share sheet to print the PDF receipt',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareReceipt(subjectHint: 'Print receipt');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Rect? _shareOriginFor(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;

    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    if (size.width <= 0 || size.height <= 0) return null;

    return Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          key: _shareKey,
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
                      widget.paymentMethod,
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryRow(
                      Icons.payments_outlined,
                      'Amount Paid',
                      '$_currencySymbol${widget.amountPaid.toStringAsFixed(2)}',
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
                      '$_currencySymbol${widget.cashRemaining.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _showShareOptions,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Share Receipt'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _shareReceipt(subjectHint: 'Download receipt'),
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

class _ShareOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
}
