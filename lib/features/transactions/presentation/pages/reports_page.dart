import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
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
  final _currencySymbol = Get.find<ProfileController>().currencySymbol;
  _ReportRange _range = _ReportRange.today;

  static const _rows = [
    _ReportRow(
      label: 'Today',
      dateRange: 'Oct 18, 2024',
      cardPayments: 4125.40,
      expenses: 2832.18,
    ),
    _ReportRow(
      label: 'Weekly',
      dateRange: 'Oct 12 – Oct 18',
      cardPayments: 27845.63,
      expenses: 18250.74,
    ),
    _ReportRow(
      label: 'Monthly',
      dateRange: 'October 2024',
      cardPayments: 115420.30,
      expenses: 72314.89,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _rows[_range.index];

    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Reports', trailing: const UserAvatar(size: 38)),
          Expanded(
            child: SingleChildScrollView(
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
                          background: AppColors.cardBackground,
                          foreground: AppColors.textPrimary,
                          border: true,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Expenses',
                          value: current.expenses,
                          background: TransactionColors.coral,
                          foreground: Colors.white,
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
                  ..._rows.map(_buildBreakdownRow),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TransactionColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          color: TransactionColors.greenDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Card payments are up 11.8% vs last week',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: TransactionColors.green,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'View Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.fieldBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Download PDF Statement'),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            row.dateRange,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Card Payments',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_currencySymbol${row.cardPayments.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Expenses',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_currencySymbol${row.expenses.toStringAsFixed(2)}',
                style: TextStyle(
                  color: TransactionColors.coral,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
  final Color background;
  final Color foreground;
  final bool border;

  const _StatCard({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: border ? Border.all(color: AppColors.fieldBorder) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${Get.find<ProfileController>().currencySymbol}${value.toStringAsFixed(2)}',
            style: TextStyle(
              color: foreground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
