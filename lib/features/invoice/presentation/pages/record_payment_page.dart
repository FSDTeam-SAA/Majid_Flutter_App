import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../widgets/invoice_input_field.dart';
import 'payment_recorded_page.dart';

/// Matches the client's "Record Payment" mockup for the Purchase invoice
/// flow: choose Cash or Bank Transfer, fill bank details if needed, then
/// hand off to [PaymentRecordedPage] with the finished receipt.
class RecordPaymentPage extends StatefulWidget {
  final double invoiceTotal;
  final double availableCash;
  final Future<File?> Function({required String paymentMethod}) onSubmitPayment;

  const RecordPaymentPage({
    super.key,
    required this.invoiceTotal,
    required this.availableCash,
    required this.onSubmitPayment,
  });

  @override
  State<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends State<RecordPaymentPage> {
  final _currencySymbol = Get.find<ProfileController>().currencySymbol;
  bool _isCashSelected = true;
  bool _isSubmitting = false;

  final _accountHolderCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _transferredAmountCtrl = TextEditingController();
  String? _proofPath;

  static const _banks = [
    'Barclays',
    'HSBC',
    'Lloyds',
    'NatWest',
    'Santander',
    'Other',
  ];

  @override
  void dispose() {
    _accountHolderCtrl.dispose();
    _bankNameCtrl.dispose();
    _referenceCtrl.dispose();
    _transferredAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _proofPath = picked.path);
  }

  void _notPreviewableYet() {
    showErrorSnackbar(
      'Preview and share will be available once this is marked as paid.',
    );
  }

  Future<void> _submit() async {
    if (!_isCashSelected && _accountHolderCtrl.text.trim().isEmpty) {
      showErrorSnackbar('Please enter the account holder name');
      return;
    }

    setState(() => _isSubmitting = true);
    final file = await widget.onSubmitPayment(
      paymentMethod: _isCashSelected ? 'cash' : 'bank_transfer',
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (file == null) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentRecordedPage(
          receiptFile: file,
          paymentMethod: _isCashSelected ? 'Cash' : 'Bank Transfer',
          amountPaid: widget.invoiceTotal,
          cashRemaining: widget.availableCash - widget.invoiceTotal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Record Payment'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Invoice Total', widget.invoiceTotal),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Available Cash',
                    widget.availableCash,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'CHOOSE PAYMENT METHOD',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildMethodCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Pay from Available Cash',
                    subtitle:
                        'Available Cash: $_currencySymbol${widget.availableCash.toStringAsFixed(2)}',
                    selected: _isCashSelected,
                    onTap: () => setState(() => _isCashSelected = true),
                  ),
                  const SizedBox(height: 10),
                  _buildMethodCard(
                    icon: Icons.account_balance_outlined,
                    title: 'Bank Transfer',
                    subtitle: 'Customer will transfer to your account',
                    selected: !_isCashSelected,
                    onTap: () => setState(() => _isCashSelected = false),
                  ),
                  if (!_isCashSelected) ...[
                    const SizedBox(height: 20),
                    Text(
                      'CUSTOMER BANK TRANSFER DETAILS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InvoiceInputField(
                      hint: 'Account Holder Name*',
                      controller: _accountHolderCtrl,
                    ),
                    const SizedBox(height: 10),
                    InvoiceInputField(
                      hint: 'Bank Name',
                      controller: _bankNameCtrl,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _banks
                          .map(
                            (bank) => GestureDetector(
                              onTap: () =>
                                  setState(() => _bankNameCtrl.text = bank),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _bankNameCtrl.text == bank
                                      ? AppColors.primary.withValues(
                                          alpha: 0.14,
                                        )
                                      : AppColors.fieldBackground,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _bankNameCtrl.text == bank
                                        ? AppColors.primary
                                        : AppColors.fieldBorder,
                                  ),
                                ),
                                child: Text(
                                  bank,
                                  style: TextStyle(
                                    color: _bankNameCtrl.text == bank
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    InvoiceInputField(
                      hint: 'Reference / Notes',
                      controller: _referenceCtrl,
                    ),
                    const SizedBox(height: 10),
                    InvoiceInputField(
                      hint: 'Transferred Amount ($_currencySymbol)',
                      controller: _transferredAmountCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickProof,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fieldBackground,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: AppColors.fieldBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.upload_file_outlined,
                              color: AppColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _proofPath != null
                                    ? 'Proof attached'
                                    : 'Transfer Confirmation — Upload / Choose File',
                                style: TextStyle(
                                  color: _proofPath != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  AppButton(
                    label: _isSubmitting
                        ? 'Please wait...'
                        : (_isCashSelected ? 'Pay from Cash' : 'Mark as Paid'),
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                  if (!_isCashSelected) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _notPreviewableYet,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.fieldBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Preview Receipt'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _notPreviewableYet,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.fieldBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Send Receipt'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          '$_currencySymbol${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color ?? AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.fieldBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
