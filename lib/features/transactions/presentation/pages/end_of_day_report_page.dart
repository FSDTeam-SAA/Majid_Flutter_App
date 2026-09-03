import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../widgets/transaction_colors.dart';

/// The mockup's End of Day Report: live totals for today plus a full list of
/// today's transactions, with no customer or card fields anywhere on it.
///
/// Sales, transaction count, card, cash and items sold are computed live from
/// today's invoices, since that data already loads on the Transactions page.
/// Refunds and discounts show as £0.00 until the backend records them - the
/// invoice model has no field for either yet, so today they can only ever
/// read zero rather than the true figure. Printing is disabled until a
/// printer is wired in and it can actually be written to the audit log the
/// spec requires.
class EndOfDayReportPage extends StatelessWidget {
  final List<Invoice> invoices;
  final String currencySymbol;

  const EndOfDayReportPage({
    super.key,
    required this.invoices,
    required this.currencySymbol,
  });

  List<Invoice> get _today {
    final now = DateTime.now();
    return invoices.where((invoice) {
      final date = DateTime.tryParse(invoice.createdAt ?? '');
      if (date == null) return false;
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList()..sort((a, b) {
      final da = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(1970);
      final db = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(1970);
      return db.compareTo(da);
    });
  }

  bool _isExpense(Invoice i) => i.type.trim().toLowerCase() == 'purchase';

  bool _isCard(Invoice i) {
    final m = (i.paymentMethod ?? '').trim().toLowerCase();
    return m.contains('card') || m.contains('bank') || m.contains('transfer');
  }

  double _amount(Invoice i) => i.amountPaid ?? i.totalAmount ?? 0;

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final sales = today
        .where((i) => !_isExpense(i))
        .fold<double>(0, (sum, i) => sum + _amount(i));
    final card = today
        .where((i) => !_isExpense(i) && _isCard(i))
        .fold<double>(0, (sum, i) => sum + _amount(i));
    final cash = today
        .where((i) => !_isExpense(i) && !_isCard(i))
        .fold<double>(0, (sum, i) => sum + _amount(i));

    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            _header(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  Text(
                    'Today · ${_formatDate(DateTime.now())}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _statGrid(sales, today.length, card, cash),
                  const SizedBox(height: 22),
                  Text(
                    "Today's Transactions",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _transactionsTable(today),
                  const SizedBox(height: 16),
                  _privacyNote(),
                  const SizedBox(height: 18),
                  _printButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'End of Day Report',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statGrid(double sales, int count, double card, double cash) {
    Widget cell(String label, String value, {Color? color, bool wide = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: color ?? AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: cell(
                'Total Sales',
                '$currencySymbol${sales.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: cell('Transactions', '$count')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: cell('Card', '$currencySymbol${card.toStringAsFixed(2)}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: cell('Cash', '$currencySymbol${cash.toStringAsFixed(2)}'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: cell(
                'Refunds',
                '$currencySymbol${0.00.toStringAsFixed(2)}',
                color: TransactionColors.coral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: cell(
                'Discounts',
                '$currencySymbol${0.00.toStringAsFixed(2)}',
                color: TransactionColors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _transactionsTable(List<Invoice> today) {
    if (today.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 26),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Text(
          'No transactions recorded today.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _headCell('Time', 2),
                _headCell('Transaction', 3),
                _headCell('Reference', 3),
                _headCell('Amount', 2, alignEnd: true),
              ],
            ),
          ),
          Divider(color: AppColors.fieldBorder, height: 1),
          for (final invoice in today) _row(invoice),
        ],
      ),
    );
  }

  Widget _headCell(String label, int flex, {bool alignEnd = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _row(Invoice invoice) {
    final date = DateTime.tryParse(invoice.createdAt ?? '');
    final time = date == null ? '—' : _formatTime(date);
    final isExpense = _isExpense(invoice);
    final amount = _amount(invoice);
    final id = invoice.id;
    final ref = id.isEmpty
        ? '—'
        : 'INV-${id.substring(id.length > 6 ? id.length - 6 : 0)}'
              .toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              time,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              isExpense
                  ? 'Inventory Purchase'
                  : (_isCard(invoice) ? 'Card Payment' : 'Cash Sale'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              ref,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${isExpense ? '-' : '+'}$currencySymbol${amount.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isExpense
                    ? TransactionColors.coral
                    : TransactionColors.greenText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyNote() {
    return Row(
      children: [
        Icon(Icons.shield_outlined, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          'No customer or card details included',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _printButton(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: 0.5,
          child: IgnorePointer(
            child: Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TransactionColors.greenBright,
                    TransactionColors.green,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.print_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Print End of Day Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect a receipt printer in Settings to print this report. '
          'Every print is recorded in the audit log.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m ${date.hour >= 12 ? 'PM' : 'AM'}';
  }
}
