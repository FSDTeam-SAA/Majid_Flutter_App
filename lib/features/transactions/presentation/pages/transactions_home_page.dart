import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../invoice/presentation/widgets/invoice_input_field.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';
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
  final _currencySymbol = Get.find<ProfileController>().currencySymbol;
  late final CashManagementRepository _cashRepo;
  late final ProfileController _profileCtrl;

  bool _balanceHidden = false;
  final List<TransactionEntry> _transactions = List.of(sampleTransactions);

  double _totalBalance = 15804.25;
  double _cashBalance = 9245.35;
  final double _cardPayments = 4125.40;
  final double _expenseToday = 2832.18;

  @override
  void initState() {
    super.initState();
    _cashRepo = CashManagementRepositoryImpl(ApiClient(baseUrl));
    _profileCtrl = Get.find<ProfileController>();
    _loadLiveData();
  }

  Future<void> _loadLiveData() async {
    try {
      final id = _profileCtrl.userId;
      if (id.isNotEmpty) {
        final cashData = await _cashRepo.getCashManagement(id);
        if (cashData != null && mounted) {
          setState(() {
            _cashBalance = cashData.cashInDrawer;
            _totalBalance = _cashBalance + _cardPayments;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _scanForRefund() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (!mounted || code == null || code.trim().isEmpty) return;
    await _showRefundSheet(code.trim());
  }

  Future<void> _showRefundSheet(String invoiceCode) async {
    var isCash = true;
    final amountCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
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
                  const SizedBox(height: 18),
                  Text(
                    'Process Return / Refund',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Invoice: $invoiceCode',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _RefundMethodButton(
                          label: 'Cash',
                          selected: isCash,
                          onTap: () => setSheetState(() => isCash = true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RefundMethodButton(
                          label: 'Card',
                          selected: !isCash,
                          onTap: () => setSheetState(() => isCash = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Refund Amount',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InvoiceInputField(
                    hint: '0.00',
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Confirm Refund',
                    onPressed: () {
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (amount == null || amount <= 0) return;
                      setState(() {
                        _transactions.insert(
                          0,
                          TransactionEntry(
                            title: 'Refund Issued',
                            subtitle: 'Invoice $invoiceCode',
                            time: 'Just now',
                            amount: -amount,
                            kind: TransactionKind.refund,
                          ),
                        );
                      });
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Refund of $_currencySymbol${amount.toStringAsFixed(2)} (${isCash ? 'Cash' : 'Card'}) recorded.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: TransactionColors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'imoscan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _scanForRefund,
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: AppColors.textPrimary,
                        size: 19,
                      ),
                    ),
                  ),
                  const UserAvatar(size: 38),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5.5,
                ),
                decoration: BoxDecoration(
                  color: TransactionColors.green.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_outward,
                      color: TransactionColors.greenText,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '12.4% vs last 7 days',
                      style: TextStyle(
                        color: TransactionColors.greenText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Cash Balance',
                      sub: 'Available',
                      value: _cashBalance,
                      icon: Icons.account_balance_wallet_outlined,
                      background: TransactionColors.green,
                      foreground: Colors.white,
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
                      icon: Icons.credit_card,
                      background: AppColors.cardBackground,
                      foreground: AppColors.textPrimary,
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
                      icon: Icons.show_chart,
                      background: TransactionColors.coral,
                      foreground: Colors.white,
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
              ..._transactions.map((entry) => TransactionTile(entry: entry)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TransactionColors.green.withValues(alpha: 0.14),
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
                        'Your earnings are up 12.4% vs last 7 days',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'View all',
                      style: TextStyle(
                        color: TransactionColors.greenText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
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
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.label,
    required this.sub,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: background == AppColors.cardBackground
              ? Border.all(color: AppColors.fieldBorder)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(height: 10),
            Text(
              '${Get.find<ProfileController>().currencySymbol}${value.toStringAsFixed(2)}',
              style: TextStyle(
                color: foreground,
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.9),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              sub,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.72),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefundMethodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RefundMethodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? TransactionColors.green : AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? TransactionColors.green : AppColors.fieldBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
