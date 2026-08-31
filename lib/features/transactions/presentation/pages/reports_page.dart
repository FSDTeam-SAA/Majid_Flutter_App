import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/more_menu_button.dart';
import '../../../invoice/data/repositories/invoice_repository_impl.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../../invoice/domain/repositories/invoice_repository.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../widgets/payment_method_icon.dart';
import '../widgets/transaction_colors.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

enum _ReportRange { today, weekly, monthly }

class _ReportRow {
  final String label;
  final String dateRange;
  final double cardPayments;
  final double expenses;

  const _ReportRow({
    required this.label,
    required this.dateRange,
    required this.cardPayments,
    required this.expenses,
  });
}

class _ReportsPageState extends State<ReportsPage> {
  // A getter, not a field: captured at construction this read the
  // GBP fallback before the profile had loaded and never updated.
  String get _currencySymbol => Get.find<ProfileController>().currencySymbol;
  late final InvoiceRepository _invoiceRepo;
  late final ProfileController _profileCtrl;

  _ReportRange _range = _ReportRange.today;
  bool _isLoading = true;
  String _errorMessage = '';
  List<Invoice> _invoices = [];

  @override
  void initState() {
    super.initState();
    _invoiceRepo = InvoiceRepositoryImpl(ApiClient(baseUrl));
    _profileCtrl = Get.find<ProfileController>();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var id = _profileCtrl.userId;
      if (id.isEmpty) {
        await _profileCtrl.fetchProfile();
        id = _profileCtrl.userId;
      }
      if (id.isEmpty) {
        throw Exception('User profile not found');
      }

      final invoices = await _invoiceRepo.getInvoices(id);
      if (!mounted) return;
      setState(() => _invoices = invoices);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Failed to load reports');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_ReportRow> get _rows {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month);

    return [
      _ReportRow(
        label: 'Today',
        dateRange: _formatDate(todayStart),
        cardPayments: _sumInvoices(
          from: todayStart,
          to: now,
          filter: (invoice) =>
              _isIncomingInvoice(invoice) && _isCardLike(invoice),
        ),
        expenses: _sumInvoices(
          from: todayStart,
          to: now,
          filter: _isExpenseInvoice,
        ),
      ),
      _ReportRow(
        label: 'Weekly',
        dateRange: '${_formatDate(weekStart)} - ${_formatDate(now)}',
        cardPayments: _sumInvoices(
          from: weekStart,
          to: now,
          filter: (invoice) =>
              _isIncomingInvoice(invoice) && _isCardLike(invoice),
        ),
        expenses: _sumInvoices(
          from: weekStart,
          to: now,
          filter: _isExpenseInvoice,
        ),
      ),
      _ReportRow(
        label: 'Monthly',
        dateRange: _formatMonth(monthStart),
        cardPayments: _sumInvoices(
          from: monthStart,
          to: now,
          filter: (invoice) =>
              _isIncomingInvoice(invoice) && _isCardLike(invoice),
        ),
        expenses: _sumInvoices(
          from: monthStart,
          to: now,
          filter: _isExpenseInvoice,
        ),
      ),
    ];
  }

  double _sumInvoices({
    required DateTime from,
    required DateTime to,
    required bool Function(Invoice invoice) filter,
  }) {
    return _invoices.fold<double>(0, (sum, invoice) {
      final createdAt = DateTime.tryParse(invoice.createdAt ?? '');
      if (createdAt == null) return sum;
      if (createdAt.isBefore(from) || createdAt.isAfter(to)) return sum;
      if (!filter(invoice)) return sum;
      return sum + (invoice.amountPaid ?? invoice.totalAmount ?? 0);
    });
  }

  bool _isIncomingInvoice(Invoice invoice) =>
      invoice.type.trim().toLowerCase() != 'purchase';

  bool _isExpenseInvoice(Invoice invoice) =>
      invoice.type.trim().toLowerCase() == 'purchase';

  bool _isCardLike(Invoice invoice) {
    final method = (invoice.paymentMethod ?? '').trim().toLowerCase();
    return method.contains('card') ||
        method.contains('bank') ||
        method.contains('transfer');
  }

  String _formatDate(DateTime value) {
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  String _formatMonth(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final current = rows[_range.index];

    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Reports', trailing: const MoreMenuButton(size: 38)),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Card Payments & Expenses',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRangeSelector(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Card Payments',
                                value: current.cardPayments,
                                method: 'card',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: 'Expenses',
                                value: current.expenses,
                                method: 'cash',
                                isExpense: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Breakdown',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...rows.map(_buildBreakdownRow),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: TransactionColors.green.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.insights_outlined,
                                color: TransactionColors.greenText,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  current.cardPayments >= current.expenses
                                      ? 'Card payments are currently ahead of purchase expenses'
                                      : 'Purchase expenses are currently higher than card payments',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: _ReportRange.values.map((range) {
          final isSelected = range == _range;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _range = range),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? TransactionColors.green : null,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  switch (range) {
                    _ReportRange.today => 'Today',
                    _ReportRange.weekly => 'Weekly',
                    _ReportRange.monthly => 'Monthly',
                  },
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBreakdownRow(_ReportRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            row.dateRange,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const PaymentMethodIcon(method: 'card', size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Card Payments',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '$_currencySymbol${row.cardPayments.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const PaymentMethodIcon(method: 'cash', size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Expenses',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                '$_currencySymbol${row.expenses.toStringAsFixed(2)}',
                style: TextStyle(
                  color: TransactionColors.coral,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;

  /// Payment method this card summarises; drives the icon and its tint.
  final String method;
  final bool isExpense;

  const _StatCard({
    required this.label,
    required this.value,
    required this.method,
    this.isExpense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PaymentMethodIcon(method: method, size: 26),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${Get.find<ProfileController>().currencySymbol}'
              '${value.toStringAsFixed(2)}',
              maxLines: 1,
              style: TextStyle(
                color: isExpense
                    ? TransactionColors.coral
                    : AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
