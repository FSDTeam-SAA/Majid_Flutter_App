import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../domain/entities/transaction_entry.dart';
import '../widgets/transaction_colors.dart';

class CashManagementPage extends StatefulWidget {
  const CashManagementPage({super.key});

  @override
  State<CashManagementPage> createState() => _CashManagementPageState();
}

class _CashManagementPageState extends State<CashManagementPage> {
  final _currencySymbol = Get.find<ProfileController>().currencySymbol;
  final _amountCtrl = TextEditingController(text: '6413.17');

  static const _totalCashAvailable = 9245.35;
  static const _cashUsed = 2832.18;
  static const _remainingToBank = 6413.17;
  static const _bankedToOwner = 2800.00;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'Cash Management',
            trailing: const UserAvatar(size: 38),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track and manage your cash',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Total Cash Available',
                    value: _totalCashAvailable,
                    background: TransactionColors.green,
                    foreground: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    icon: Icons.arrow_downward,
                    label: 'Cash Used',
                    value: -_cashUsed,
                    background: AppColors.cardBackground,
                    foreground: AppColors.textPrimary,
                    iconColor: TransactionColors.coral,
                    border: true,
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    icon: Icons.account_balance_outlined,
                    label: 'Remaining to Bank',
                    value: _remainingToBank,
                    background: AppColors.cardBackground,
                    foreground: AppColors.textPrimary,
                    iconColor: TransactionColors.blue,
                    border: true,
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    icon: Icons.check_circle_outline,
                    label: 'Banked to Owner Account',
                    value: _bankedToOwner,
                    background: TransactionColors.green,
                    foreground: Colors.white,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cash Used Breakdown',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Today',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...sampleCashBreakdown.map(_buildBreakdownTile),
                  const SizedBox(height: 24),
                  Text(
                    'Bank to Owner Account',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
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
                                () => _amountCtrl.text = _remainingToBank
                                    .toStringAsFixed(2),
                              ),
                              child: Text(
                                'Use Remaining',
                                style: TextStyle(
                                  color: TransactionColors.greenDark,
                                  fontSize: 12,
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
                    label:
                        'Deposit All ($_currencySymbol${_remainingToBank.toStringAsFixed(2)})',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.fieldBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Transfer to Owner Account'),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  }) {
    return Container(
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
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
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
    );
  }

  Widget _buildBreakdownTile(CashBreakdownEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: TransactionColors.coral.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: TransactionColors.coral,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              entry.label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-$_currencySymbol${entry.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: TransactionColors.coral,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.time,
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
