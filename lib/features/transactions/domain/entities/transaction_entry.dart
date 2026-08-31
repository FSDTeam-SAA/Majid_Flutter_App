import 'package:flutter/material.dart';

enum TransactionKind { cashReceived, cardReceived, expense, refund }

class TransactionEntry {
  final String title;
  final String subtitle;
  final String time;
  final double amount;
  final TransactionKind kind;

  /// How it was paid (Cash, Card, Bank Transfer, ...). Empty when the invoice
  /// did not record one; the tile then falls back to [kind].
  final String method;

  const TransactionEntry({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.amount,
    required this.kind,
    this.method = '',
  });

  bool get isCredit =>
      kind == TransactionKind.cashReceived ||
      kind == TransactionKind.cardReceived;

  IconData get icon {
    switch (kind) {
      case TransactionKind.cashReceived:
        return Icons.compare_arrows_rounded;
      case TransactionKind.cardReceived:
        return Icons.credit_card_rounded;
      case TransactionKind.expense:
        return Icons.call_made_rounded;
      case TransactionKind.refund:
        return Icons.swap_horiz_rounded;
    }
  }
}

class CashBreakdownEntry {
  final String label;
  final String time;
  final double amount;

  const CashBreakdownEntry({
    required this.label,
    required this.time,
    required this.amount,
  });
}

/// Sample data — a design/UI pass, matching the reference mockups. Swap for
/// a repository call once the backend has a transactions/cash-flow endpoint.
const sampleTransactions = [
  TransactionEntry(
    title: 'Cash Received',
    subtitle: 'From Customer',
    time: 'Today, 09:14 AM',
    amount: 320.00,
    kind: TransactionKind.cashReceived,
  ),
  TransactionEntry(
    title: 'Card Payment Received',
    subtitle: 'Visa •••• 4082',
    time: 'Today, 09:02 AM',
    amount: 650.00,
    kind: TransactionKind.cardReceived,
  ),
  TransactionEntry(
    title: 'Shop Expense',
    subtitle: 'Inventory Purchase',
    time: 'Yesterday, 07:21 AM',
    amount: -185.60,
    kind: TransactionKind.expense,
  ),
  TransactionEntry(
    title: 'Cash Received',
    subtitle: 'From Customer',
    time: 'Yesterday, 03:47 PM',
    amount: 120.00,
    kind: TransactionKind.cashReceived,
  ),
  TransactionEntry(
    title: 'Shop Expense',
    subtitle: 'Marketing Supplies',
    time: 'Yesterday, 02:50 PM',
    amount: -65.75,
    kind: TransactionKind.expense,
  ),
  TransactionEntry(
    title: 'Card Payment Received',
    subtitle: 'Mastercard •••• 7710',
    time: 'Yesterday, 11:34 AM',
    amount: 420.00,
    kind: TransactionKind.cardReceived,
  ),
];

const sampleCashBreakdown = [
  CashBreakdownEntry(
    label: 'Inventory Purchase',
    time: '07:21 AM',
    amount: 1185.60,
  ),
  CashBreakdownEntry(label: 'Petty Cash', time: '10:05 AM', amount: 320.00),
  CashBreakdownEntry(
    label: 'Marketing Supplies',
    time: '01:15 PM',
    amount: 465.75,
  ),
  CashBreakdownEntry(label: 'Staff Meal', time: '05:10 PM', amount: 260.93),
  CashBreakdownEntry(label: 'Miscellaneous', time: '05:42 PM', amount: 600.00),
];
