import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../domain/entities/transaction_entry.dart';
import 'transaction_colors.dart';

class TransactionTile extends StatelessWidget {
  final TransactionEntry entry;

  const TransactionTile({super.key, required this.entry});

  Color get _iconColor {
    switch (entry.kind) {
      case TransactionKind.cashReceived:
        return TransactionColors.green;
      case TransactionKind.cardReceived:
        return TransactionColors.blue;
      case TransactionKind.expense:
        return TransactionColors.coral;
      case TransactionKind.refund:
        return TransactionColors.coral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = entry.isCredit
        ? TransactionColors.greenBright
        : TransactionColors.coral;
    final sign = entry.isCredit ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(entry.icon, color: _iconColor, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${Get.find<ProfileController>().currencySymbol}${entry.amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
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
