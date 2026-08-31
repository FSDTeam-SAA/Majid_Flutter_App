import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../domain/entities/transaction_entry.dart';
import 'payment_method_icon.dart';
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
          Builder(
            builder: (context) {
              // Prefer the recorded payment method so cash, card and bank
              // transfers are told apart at a glance.
              final hasMethod = entry.method.trim().isNotEmpty;
              final style = hasMethod
                  ? PaymentMethodIcon.styleFor(entry.method)
                  : null;
              final tint = style == null
                  ? _iconColor
                  : PaymentMethodIcon.readableTint(style.color);

              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: Icon(style?.icon ?? entry.icon, color: tint, size: 24),
              );
            },
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
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
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
                  fontSize: 17.5,
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
