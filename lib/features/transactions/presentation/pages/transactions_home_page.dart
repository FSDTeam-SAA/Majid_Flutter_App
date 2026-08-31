import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/more_menu_button.dart';
import '../../../invoice/data/repositories/invoice_repository_impl.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../../invoice/domain/repositories/invoice_repository.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../domain/entities/transaction_entry.dart';
import '../widgets/transaction_colors.dart';
import '../widgets/transaction_tile.dart';
import 'cash_management_page.dart';
import 'reports_page.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../data/repositories/cash_management_repository_impl.dart';
import '../../domain/repositories/cash_management_repository.dart';

class TransactionsHomePage extends StatefulWidget {
  const TransactionsHomePage({super.key});

  @override
  State<TransactionsHomePage> createState() => _TransactionsHomePageState();
}

class _TransactionsHomePageState extends State<TransactionsHomePage> {
  // A getter, not a field: captured at construction this read the
  // GBP fallback before the profile had loaded and never updated.
  String get _currencySymbol => Get.find<ProfileController>().currencySymbol;
  late final CashManagementRepository _cashRepo;
  late final InvoiceRepository _invoiceRepo;
  late final ProfileController _profileCtrl;

  bool _balanceHidden = false;
  final List<TransactionEntry> _transactions = [];

  double _totalBalance = 0;
  double _cashBalance = 0;
  double _cardPayments = 0;
  double _expenseToday = 0;
  double _trendPercent = 0;

  @override
  void initState() {
    super.initState();
    _cashRepo = CashManagementRepositoryImpl(ApiClient(baseUrl));
    _invoiceRepo = InvoiceRepositoryImpl(ApiClient(baseUrl));
    _profileCtrl = Get.find<ProfileController>();
    _loadLiveData();
  }

  Future<void> _loadLiveData() async {
    try {
      var id = _profileCtrl.userId;
      if (id.isEmpty) {
        await _profileCtrl.fetchProfile();
        id = _profileCtrl.userId;
      }
      if (id.isEmpty) return;

      final results = await Future.wait([
        _cashRepo.getCashManagement(id),
        _invoiceRepo.getInvoices(id),
      ]);
      final cashData = results[0] as dynamic;
      final invoices = results[1] as List<Invoice>;

      final transactions = _buildTransactionsFromInvoices(invoices);
      final totalCardPayments = _sumInvoices(
        invoices,
        filter: (invoice) =>
            _isIncomingInvoice(invoice) && _isCardLike(invoice),
      );
      final todayCardPayments = _sumInvoices(
        invoices,
        filter: (invoice) =>
            _isIncomingInvoice(invoice) &&
            _isCardLike(invoice) &&
            _isSameDay(_invoiceDate(invoice), DateTime.now()),
      );
      final todayExpense = _sumInvoices(
        invoices,
        filter: (invoice) =>
            _isExpenseInvoice(invoice) &&
            _isSameDay(_invoiceDate(invoice), DateTime.now()),
      );
      final cashSales = _sumInvoices(
        invoices,
        filter: (invoice) =>
            _isIncomingInvoice(invoice) && _isCashLike(invoice),
      );

      if (!mounted) return;
      setState(() {
        _transactions
          ..clear()
          ..addAll(transactions);
        _cashBalance = cashData?.cashInDrawer ?? cashSales;
        _cardPayments = todayCardPayments;
        _expenseToday = todayExpense;
        _totalBalance = _cashBalance + totalCardPayments;
        _trendPercent = _calculateTrendPercent(invoices);
      });
    } catch (_) {}
  }

  List<TransactionEntry> _buildTransactionsFromInvoices(
    List<Invoice> invoices,
  ) {
    final sorted = List<Invoice>.from(invoices)
      ..sort((a, b) => _invoiceDate(b).compareTo(_invoiceDate(a)));

    return sorted
        .where((invoice) => _invoiceAmount(invoice) > 0)
        .take(8)
        .map(
          (invoice) => TransactionEntry(
            title: _transactionTitle(invoice),
            subtitle: _transactionSubtitle(invoice),
            time: _formatRelativeTime(_invoiceDate(invoice)),
            amount: _isExpenseInvoice(invoice)
                ? -_invoiceAmount(invoice)
                : _invoiceAmount(invoice),
            kind: _transactionKind(invoice),
            method: (invoice.paymentMethod ?? '').trim(),
          ),
        )
        .toList();
  }

  TransactionKind _transactionKind(Invoice invoice) {
    if (_isExpenseInvoice(invoice)) return TransactionKind.expense;
    if (_isCardLike(invoice)) return TransactionKind.cardReceived;
    return TransactionKind.cashReceived;
  }

  String _transactionTitle(Invoice invoice) {
    if (_isExpenseInvoice(invoice)) return 'Inventory Purchase';
    if (_isCardLike(invoice)) return 'Card Payment Received';
    return 'Cash Received';
  }

  String _transactionSubtitle(Invoice invoice) {
    final type = invoice.type.trim().isEmpty ? 'invoice' : invoice.type.trim();
    final rawCustomer = invoice.customerName.trim();
    final isMissing = rawCustomer.isEmpty || rawCustomer.toUpperCase() == 'N/A';
    final customer = isMissing ? 'Walk-in customer' : rawCustomer;
    return '$customer • ${_titleCase(type)}';
  }

  double _invoiceAmount(Invoice invoice) {
    return invoice.amountPaid ?? invoice.totalAmount ?? 0;
  }

  DateTime _invoiceDate(Invoice invoice) {
    return DateTime.tryParse(invoice.createdAt ?? '') ?? DateTime(1970);
  }

  bool _isIncomingInvoice(Invoice invoice) {
    return !_isExpenseInvoice(invoice);
  }

  bool _isExpenseInvoice(Invoice invoice) {
    return invoice.type.trim().toLowerCase() == 'purchase';
  }

  bool _isCardLike(Invoice invoice) {
    final method = (invoice.paymentMethod ?? '').trim().toLowerCase();
    return method.contains('card') ||
        method.contains('bank') ||
        method.contains('transfer');
  }

  bool _isCashLike(Invoice invoice) {
    final method = (invoice.paymentMethod ?? '').trim().toLowerCase();
    return method.isEmpty || method.contains('cash');
  }

  double _sumInvoices(
    List<Invoice> invoices, {
    required bool Function(Invoice invoice) filter,
  }) {
    return invoices.fold<double>(0, (sum, invoice) {
      if (!filter(invoice)) return sum;
      return sum + _invoiceAmount(invoice);
    });
  }

  double _calculateTrendPercent(List<Invoice> invoices) {
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 7));
    final previousStart = now.subtract(const Duration(days: 14));

    final current = invoices.fold<double>(0, (sum, invoice) {
      final date = _invoiceDate(invoice);
      if (!_isIncomingInvoice(invoice) ||
          date.isBefore(currentStart) ||
          date.isAfter(now)) {
        return sum;
      }
      return sum + _invoiceAmount(invoice);
    });

    final previous = invoices.fold<double>(0, (sum, invoice) {
      final date = _invoiceDate(invoice);
      if (!_isIncomingInvoice(invoice) ||
          date.isBefore(previousStart) ||
          !date.isBefore(currentStart)) {
        return sum;
      }
      return sum + _invoiceAmount(invoice);
    });

    if (previous <= 0) {
      return current > 0 ? 100 : 0;
    }
    return ((current - previous) / previous) * 100;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatRelativeTime(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && _isSameDay(value, now)) {
      return 'Today, ${_formatClock(value)}';
    }
    if (diff.inHours < 48 &&
        _isSameDay(value.add(const Duration(days: 1)), now)) {
      return 'Yesterday, ${_formatClock(value)}';
    }
    return '${value.day}/${value.month}/${value.year}';
  }

  String _formatClock(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _titleCase(String value) {
    final words = value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty);
    return words
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Obx(() {
                    final shopName = _profileCtrl.shopName.trim().isNotEmpty
                        ? _profileCtrl.shopName.trim()
                        : 'Your Shop';
                    final ownerName = _profileCtrl.fullName.trim();

                    // Logo lives in the More menu now, not in page headers.
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          ownerName.isNotEmpty
                              ? ownerName
                              : 'Transactions overview',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    );
                  }),
                  const Spacer(),
                  const MoreMenuButton(size: 38),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _balanceHidden = !_balanceHidden),
                    child: Icon(
                      _balanceHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _balanceHidden
                    ? '$_currencySymbol••••••'
                    : '$_currencySymbol${_totalBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  // A fall was still painted green before, which read as good
                  // news. Colour now follows the sign.
                  final isUp = _trendPercent >= 0;
                  final tone = isUp
                      ? TransactionColors.greenText
                      : TransactionColors.coral;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 5.5,
                    ),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: tone,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${isUp ? '+' : ''}'
                          '${_trendPercent.toStringAsFixed(1)}% vs last 7 days',
                          style: TextStyle(
                            color: tone,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Cash Balance',
                      sub: 'Available',
                      value: _cashBalance,
                      icon: Icons.account_balance_wallet_rounded,
                      accent: TransactionColors.greenBright,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CashManagementPage(),
                        ),
                      ).then((_) => _loadLiveData()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Card Payments',
                      sub: "Today's Sales",
                      value: _cardPayments,
                      icon: Icons.credit_card_rounded,
                      accent: TransactionColors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Expense',
                      sub: 'Today',
                      value: _expenseToday,
                      icon: Icons.trending_down_rounded,
                      accent: TransactionColors.coral,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportsPage()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReportsPage()),
                    ),
                    child: Text(
                      'View all',
                      style: TextStyle(
                        color: TransactionColors.greenText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No live transactions yet.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                ..._transactions.map((entry) => TransactionTile(entry: entry)),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  // Matches the headline pill: a decline should not be dressed
                  // in the same green as growth.
                  final isUp = _trendPercent >= 0;
                  final tone = isUp
                      ? TransactionColors.greenText
                      : TransactionColors.coral;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: tone.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color: tone,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isUp
                                ? 'Your earnings are up '
                                      '${_trendPercent.toStringAsFixed(1)}% '
                                      'vs last 7 days'
                                : 'Your earnings are down '
                                      '${_trendPercent.abs().toStringAsFixed(1)}% '
                                      'vs last 7 days',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'View all',
                          style: TextStyle(
                            color: tone,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String sub;
  final double value;
  final IconData icon;

  /// Used to tint the icon chip only. Flooding each card in a different
  /// saturated colour made the three read as unrelated widgets.
  final Color accent;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.label,
    required this.sub,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 16),
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
                    color: AppColors.textPrimary,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
