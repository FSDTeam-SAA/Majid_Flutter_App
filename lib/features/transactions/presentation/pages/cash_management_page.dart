import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../invoice/data/repositories/invoice_repository_impl.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../../invoice/domain/repositories/invoice_repository.dart';
import '../../../invoice/presentation/widgets/invoice_input_field.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../data/repositories/cash_management_repository_impl.dart';
import '../../domain/entities/cash_management_data.dart';
import '../../domain/repositories/cash_management_repository.dart';
import '../widgets/transaction_colors.dart';

class CashManagementPage extends StatefulWidget {
  const CashManagementPage({super.key});

  @override
  State<CashManagementPage> createState() => _CashManagementPageState();
}

class _CashMovementItem {
  final String title;
  final String subtitle;
  final String time;
  final double amount;
  final bool isCredit;
  final IconData icon;

  const _CashMovementItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.amount,
    required this.isCredit,
    required this.icon,
  });
}

class _CashManagementPageState extends State<CashManagementPage> {
  final _currencySymbol = Get.find<ProfileController>().currencySymbol;
  final _amountCtrl = TextEditingController();

  late final CashManagementRepository _cashRepo;
  late final InvoiceRepository _invoiceRepo;
  late final ProfileController _profileCtrl;

  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  CashManagementData? _cashData;
  CashManagementStats? _cashStats;
  List<Invoice> _cashInvoices = [];

  @override
  void initState() {
    super.initState();
    final api = ApiClient(baseUrl);
    _cashRepo = CashManagementRepositoryImpl(api);
    _invoiceRepo = InvoiceRepositoryImpl(api);
    _profileCtrl = Get.find<ProfileController>();
    _loadData();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  String get _shopkeeperId {
    if (_profileCtrl.userId.isNotEmpty) return _profileCtrl.userId;
    return '';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      var id = _shopkeeperId;
      if (id.isEmpty) {
        await _profileCtrl.fetchProfile();
        id = _shopkeeperId;
      }

      if (id.isNotEmpty) {
        final results = await Future.wait([
          _cashRepo.getCashManagement(id),
          _cashRepo.getStats(id),
          _invoiceRepo.getInvoices(id).catchError((_) => <Invoice>[]),
        ]);

        _cashData = results[0] as CashManagementData?;
        _cashStats = results[1] as CashManagementStats?;
        _cashInvoices = results[2] as List<Invoice>;

        // If no cash data exists yet on backend, initialize default structure
        _cashData ??= CashManagementData(
          shopkeeperId: id,
          startingDayCash: 0.0,
          banked: 0.0,
          cashInDrawer: _calculateCashFromInvoices(_cashInvoices),
          cashManagementScore: 100,
          aiInsight:
              'Welcome to Cash Management. Set your starting day cash to begin tracking cash flow and register reconciliation.',
        );

        _amountCtrl.text = _cashData!.remainingToBank.toStringAsFixed(2);
      }
    } on DioException catch (e) {
      _errorMessage =
          e.response?.data?['message'] ?? 'Failed to load cash management';
    } catch (_) {
      _errorMessage = 'Failed to load cash management data';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _calculateCashFromInvoices(List<Invoice> invoices) {
    double total = 0;
    for (final inv in invoices) {
      total += inv.totalAmount ?? 0;
    }
    return total;
  }

  Future<void> _saveCashRecord({
    required double startingDayCash,
    required double banked,
    required double cashInDrawer,
    String? successMessage,
  }) async {
    final id = _shopkeeperId;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session not found')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await _cashRepo.createOrUpdateCashManagement(
        shopkeeperId: id,
        startingDayCash: startingDayCash,
        banked: banked,
        cashInDrawer: cashInDrawer,
      );

      setState(() {
        _cashData = updated;
        _amountCtrl.text = updated.remainingToBank.toStringAsFixed(2);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successMessage ?? 'Cash management updated successfully!',
            ),
            backgroundColor: TransactionColors.green,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message'] ?? 'Failed to save cash record',
            ),
            backgroundColor: AppColors.dangerColor,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save cash record'),
            backgroundColor: AppColors.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Actions & Modals ───

  void _showSetStartingCashModal() {
    final ctrl = TextEditingController(
      text: (_cashData?.startingDayCash ?? 0) > 0
          ? _cashData!.startingDayCash.toStringAsFixed(2)
          : '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
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
                'Opening / Starting Day Cash',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set the opening float amount in your cash drawer for the day.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              InvoiceInputField(
                hint: '0.00',
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Save Starting Cash',
                onPressed: () {
                  final amount = double.tryParse(ctrl.text.trim());
                  if (amount == null || amount < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid cash amount'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  final currentInDrawer = _cashData?.cashInDrawer ?? 0;
                  final newInDrawer =
                      currentInDrawer == 0 ? amount : currentInDrawer;
                  _saveCashRecord(
                    startingDayCash: amount,
                    banked: _cashData?.banked ?? 0,
                    cashInDrawer: newInDrawer,
                    successMessage:
                        'Starting day cash set to $_currencySymbol${amount.toStringAsFixed(2)}',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCashModal() {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
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
                'Add Cash to Drawer (Float In)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record additional cash placed into the register drawer.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              InvoiceInputField(
                hint: 'Amount (e.g. 100.00)',
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              InvoiceInputField(
                hint: 'Reason / Description (e.g. Extra Change Float)',
                controller: noteCtrl,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Add Cash',
                onPressed: () {
                  final amount = double.tryParse(ctrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid positive amount'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  final currentInDrawer = _cashData?.cashInDrawer ?? 0;
                  _saveCashRecord(
                    startingDayCash: _cashData?.startingDayCash ?? 0,
                    banked: _cashData?.banked ?? 0,
                    cashInDrawer: currentInDrawer + amount,
                    successMessage:
                        'Added $_currencySymbol${amount.toStringAsFixed(2)} to cash drawer',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRemoveCashModal() {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.viewInsetsOf(ctx).bottom + 24,
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
                'Remove Cash (Payout / Expense)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record cash taken out of drawer for store expenses or petty cash.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 16),
              InvoiceInputField(
                hint: 'Amount (e.g. 50.00)',
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              InvoiceInputField(
                hint: 'Reason / Expense (e.g. Cleaning Supplies)',
                controller: noteCtrl,
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Remove Cash',
                onPressed: () {
                  final amount = double.tryParse(ctrl.text.trim());
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid amount'),
                      ),
                    );
                    return;
                  }
                  final currentInDrawer = _cashData?.cashInDrawer ?? 0;
                  if (amount > currentInDrawer) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Amount exceeds available cash in drawer',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _saveCashRecord(
                    startingDayCash: _cashData?.startingDayCash ?? 0,
                    banked: _cashData?.banked ?? 0,
                    cashInDrawer: (currentInDrawer - amount).clamp(
                      0,
                      double.infinity,
                    ),
                    successMessage:
                        'Recorded cash payout of $_currencySymbol${amount.toStringAsFixed(2)}',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleDepositToBank(double amount) {
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount to bank')),
      );
      return;
    }

    final currentInDrawer = _cashData?.cashInDrawer ?? 0;
    if (amount > currentInDrawer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bank amount exceeds cash in drawer')),
      );
      return;
    }

    final currentBanked = _cashData?.banked ?? 0;
    final newBanked = currentBanked + amount;
    final newInDrawer = (currentInDrawer - amount).clamp(0.0, double.infinity);

    _saveCashRecord(
      startingDayCash: _cashData?.startingDayCash ?? 0,
      banked: newBanked,
      cashInDrawer: newInDrawer,
      successMessage:
          'Successfully banked $_currencySymbol${amount.toStringAsFixed(2)} to owner account!',
    );
  }

  void _showCloseRegisterModal() {
    final actualCountCtrl = TextEditingController(
      text: (_cashData?.cashInDrawer ?? 0).toStringAsFixed(2),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final counted = double.tryParse(actualCountCtrl.text.trim()) ?? 0.0;
            final expected = _cashData?.cashInDrawer ?? 0.0;
            final diff = counted - expected;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.viewInsetsOf(ctx).bottom + 24,
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
                    'Close & Reconcile Register',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Count physical cash in drawer to record any discrepancies and update cash score.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expected Cash in Drawer:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '$_currencySymbol${expected.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Actual Physical Cash Counted:',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InvoiceInputField(
                    hint: '0.00',
                    controller: actualCountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Difference / Variance:',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${diff >= 0 ? '+' : ''}$_currencySymbol${diff.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: diff.abs() < 0.01
                              ? TransactionColors.green
                              : diff < 0
                              ? TransactionColors.coral
                              : TransactionColors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Reconcile & Close Register',
                    onPressed: () {
                      Navigator.pop(ctx);
                      _saveCashRecord(
                        startingDayCash: _cashData?.startingDayCash ?? 0,
                        banked: _cashData?.banked ?? 0,
                        cashInDrawer: counted,
                        successMessage:
                            'Register reconciled and closed. AI Insight generated!',
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

  // ─── Build UI ───

  @override
  Widget build(BuildContext context) {
    final cashInDrawer = _cashData?.cashInDrawer ?? 0.0;
    final startingCash = _cashData?.startingDayCash ?? 0.0;
    final banked = _cashData?.banked ?? 0.0;
    final remainingToBank = _cashData?.remainingToBank ?? cashInDrawer;
    final score = _cashData?.cashManagementScore ?? 100;
    final aiInsight = _cashData?.aiInsight ?? '';

    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'Cash Management',
            trailing: const UserAvatar(size: 38),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: AppLoadingIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: TransactionColors.green,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.dangerColor.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.dangerColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: AppColors.dangerColor,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Track and manage your cash',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: _showCloseRegisterModal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: TransactionColors.green.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: TransactionColors.green.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 14,
                                        color: TransactionColors.greenText,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Close Register',
                                        style: TextStyle(
                                          color: TransactionColors.greenText,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Card 1: Total Cash in Drawer
                          _buildStatRow(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Cash in Drawer (Available)',
                            value: cashInDrawer,
                            background: TransactionColors.green,
                            foreground: Colors.white,
                            onTap: _showAddCashModal,
                          ),
                          const SizedBox(height: 10),

                          // Card 2: Starting Day Cash
                          _buildStatRow(
                            icon: Icons.storefront_outlined,
                            label: 'Starting Day Cash',
                            value: startingCash,
                            background: AppColors.cardBackground,
                            foreground: AppColors.textPrimary,
                            iconColor: TransactionColors.blue,
                            border: true,
                            onTap: _showSetStartingCashModal,
                          ),
                          const SizedBox(height: 10),

                          // Card 3: Remaining to Bank
                          _buildStatRow(
                            icon: Icons.account_balance_outlined,
                            label: 'Remaining to Bank',
                            value: remainingToBank,
                            background: AppColors.cardBackground,
                            foreground: AppColors.textPrimary,
                            iconColor: TransactionColors.greenBright,
                            border: true,
                          ),
                          const SizedBox(height: 10),

                          // Card 4: Banked to Owner Account
                          _buildStatRow(
                            icon: Icons.check_circle_outline,
                            label: 'Banked to Owner Account',
                            value: banked,
                            background: TransactionColors.green,
                            foreground: Colors.white,
                          ),
                          const SizedBox(height: 18),

                          // Quick Action Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Set Float',
                                  icon: Icons.tune,
                                  onTap: _showSetStartingCashModal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Add Cash',
                                  icon: Icons.add_circle_outline,
                                  onTap: _showAddCashModal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  label: 'Payout',
                                  icon: Icons.remove_circle_outline,
                                  onTap: _showRemoveCashModal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Score and AI Insight Card
                          if (aiInsight.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: TransactionColors.green.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: TransactionColors.green.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.insights,
                                            color: TransactionColors.greenText,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Cash Management Score',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: TransactionColors.green,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          '$score / 100',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    aiInsight,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (_cashStats != null &&
                                      _cashStats!.recentTrend.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Recent 30-Day Trend: ${_cashStats!.recentTrend}',
                                        style: TextStyle(
                                          color: TransactionColors.greenText,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Cash Used Breakdown / History
                          Text(
                            'Recent Cash Activity',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),

                          if (_cashInvoices.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No cash sales recorded yet today.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          else
                            ..._cashInvoices.take(5).map((inv) {
                              final amount = inv.totalAmount ?? 0.0;
                              final shortId = inv.id.length > 6
                                  ? inv.id
                                        .substring(inv.id.length - 6)
                                        .toUpperCase()
                                  : inv.id.toUpperCase();
                              return _buildMovementTile(
                                _CashMovementItem(
                                  title: 'Cash Sale',
                                  subtitle:
                                      'Invoice #$shortId • ${inv.customerName}',
                                  time: inv.createdAt ?? 'Today',
                                  amount: amount,
                                  isCredit: true,
                                  icon: Icons.swap_horiz_rounded,
                                ),
                              );
                            }),

                          const SizedBox(height: 24),

                          // Bank to Owner Account Form Section
                          Text(
                            'Bank to Owner Account',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.fieldBackground,
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: AppColors.fieldBorder),
                            ),
                            child: TextField(
                              controller: _amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter amount to bank',
                                prefixText: '$_currencySymbol ',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Center(
                                    widthFactor: 1,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _amountCtrl.text = remainingToBank
                                            .toStringAsFixed(2),
                                      ),
                                      child: Text(
                                        'Use Remaining',
                                        style: TextStyle(
                                          color: TransactionColors.greenText,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: _isSaving
                                ? 'Saving...'
                                : 'Deposit All ($_currencySymbol${remainingToBank.toStringAsFixed(2)})',
                            onPressed: _isSaving
                                ? null
                                : () => _handleDepositToBank(remainingToBank),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    final amount = double.tryParse(
                                      _amountCtrl.text.trim(),
                                    );
                                    if (amount == null || amount <= 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter a valid amount',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    _handleDepositToBank(amount);
                                  },
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: AppColors.fieldBorder),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Transfer Custom Amount to Owner Account',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: TransactionColors.greenText),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required double value,
    required Color background,
    required Color foreground,
    Color? iconColor,
    bool border = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: border ? Border.all(color: AppColors.fieldBorder) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.white).withValues(
                  alpha: iconColor != null ? 0.16 : 0.24,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 19),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (onTap != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Tap to edit',
                        style: TextStyle(
                          color: foreground.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${value < 0 ? '-' : ''}$_currencySymbol${value.abs().toStringAsFixed(2)}',
              style: TextStyle(
                color: foreground,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementTile(_CashMovementItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  (item.isCredit
                          ? TransactionColors.greenBright
                          : TransactionColors.coral)
                      .withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: item.isCredit
                  ? TransactionColors.greenBright
                  : TransactionColors.coral,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.isCredit ? '+' : '-'}$_currencySymbol${item.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: item.isCredit
                      ? TransactionColors.greenBright
                      : TransactionColors.coral,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.time,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
