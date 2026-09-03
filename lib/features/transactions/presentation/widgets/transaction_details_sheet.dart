import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/colors.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../domain/entities/transaction_entry.dart';
import 'payment_method_icon.dart';
import 'transaction_colors.dart';

/// The mockup's Transaction Details sheet. Everything the backend already
/// gives us (invoice ref, date, amount, customer, payment method, PDF) is
/// live; the rows the backend does not yet return (phone, email, item,
/// authorisation, served by) show as "Not recorded yet" rather than being
/// hidden, so the layout matches the spec today and just fills in once those
/// fields exist.
Future<void> showTransactionDetailsSheet(
  BuildContext context,
  TransactionEntry entry,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _TransactionDetailsSheet(entry: entry),
  );
}

class _TransactionDetailsSheet extends StatelessWidget {
  final TransactionEntry entry;

  const _TransactionDetailsSheet({required this.entry});

  String get _currencySymbol => Get.find<ProfileController>().currencySymbol;

  @override
  Widget build(BuildContext context) {
    final sign = entry.isCredit ? '+' : '-';
    final amountColor = entry.isCredit
        ? TransactionColors.greenBright
        : TransactionColors.coral;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Transaction details',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (entry.isPaid
                          ? TransactionColors.greenBright
                          : TransactionColors.coral)
                      .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.isPaid ? 'PAID' : 'DUE',
                  style: TextStyle(
                    color: entry.isPaid
                        ? TransactionColors.greenText
                        : TransactionColors.coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$sign$_currencySymbol${entry.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                entry.title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: AppColors.fieldBorder, height: 1),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _column([
                          _row('Invoice', _orDash(entry.invoiceRef)),
                          _row('Date & time', _dateLabel()),
                          _row('Customer', _orNotRecorded(entry.customerName)),
                          _row('Phone', _notRecorded()),
                          _row('Email', _notRecorded()),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _column([
                          _paymentMethodRow(),
                          _row('Authorisation', _notRecorded()),
                          _row('Served by', _notRecorded()),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _receiptRow(context),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _actionChip(
                      icon: Icons.print_outlined,
                      label: 'Print duplicate',
                      onTap: () => _printDuplicate(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionChip(
                      icon: Icons.mail_outline_rounded,
                      label: 'Send email',
                      onTap: () => _sendEmail(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _actionChip(
                      icon: Icons.sms_outlined,
                      label: 'Send message',
                      onTap: () => _sendMessage(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: AppColors.fieldBorder, height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _outlineAction(
                      icon: Icons.refresh_rounded,
                      label: 'Refund',
                      color: TransactionColors.coral,
                      onTap: () => _needsManagerApi(context, 'Refund'),
                    ),
                  ),
                  Container(width: 1, height: 34, color: AppColors.fieldBorder),
                  Expanded(
                    child: _outlineAction(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Exchange',
                      color: TransactionColors.blue,
                      onTap: () => _needsManagerApi(context, 'Exchange'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Manager permission required',
                  style: TextStyle(
                    color: TransactionColors.coral,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _column(List<Widget> rows) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        rows[i],
        if (i != rows.length - 1) const SizedBox(height: 12),
      ],
    ],
  );

  Widget _row(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _paymentMethodRow() {
    final style = PaymentMethodIcon.styleFor(entry.method);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment method',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            PaymentMethodIcon(method: entry.method, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                entry.method.trim().isEmpty ? style.label : entry.method,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _receiptRow(BuildContext context) {
    final hasReceipt = (entry.pdfUrl ?? '').trim().isNotEmpty;
    return GestureDetector(
      onTap: hasReceipt ? () => _openReceipt(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasReceipt ? 'Receipt PDF' : 'Receipt not available yet',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasReceipt)
              Icon(
                Icons.open_in_new_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlineAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel() {
    final date = entry.date;
    if (date == null) return entry.time;
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} · $h:$m $ampm';
  }

  String _orDash(String value) => value.trim().isEmpty ? '—' : value.trim();

  String _orNotRecorded(String value) =>
      value.trim().isEmpty ? _notRecorded() : value.trim();

  String _notRecorded() => 'Not recorded yet';

  Future<void> _openReceipt(BuildContext context) async {
    final url = entry.pdfUrl;
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _printDuplicate(BuildContext context) async {
    final url = entry.pdfUrl;
    if (url == null || url.trim().isEmpty) {
      _showSnack(context, 'No receipt file for this transaction yet');
      return;
    }
    // No printer SDK wired in yet, so this opens the system share sheet,
    // which lets the shopkeeper print via AirPrint/any share target today.
    await Share.share(url, subject: 'Receipt ${entry.invoiceRef}');
  }

  Future<void> _sendEmail(BuildContext context) async {
    _showSnack(
      context,
      'Add the customer\'s email to this invoice to send a receipt',
    );
  }

  Future<void> _sendMessage(BuildContext context) async {
    _showSnack(
      context,
      'Add the customer\'s phone number to this invoice to send a receipt',
    );
  }

  void _needsManagerApi(BuildContext context, String action) {
    _showSnack(
      context,
      '$action needs manager sign-off, coming once that\'s wired up on the '
      'server',
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
