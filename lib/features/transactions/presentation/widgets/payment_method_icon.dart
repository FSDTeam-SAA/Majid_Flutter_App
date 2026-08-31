import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import 'transaction_colors.dart';

/// Visual identity for a payment method: a tinted chip with the matching icon.
///
/// Recognises the methods the app records today (Cash, Card, Bank Transfer,
/// Online) and the card brands, so a brand shows through as soon as the
/// backend starts storing one.
class PaymentMethodIcon extends StatelessWidget {
  final String method;
  final double size;

  const PaymentMethodIcon({super.key, required this.method, this.size = 28});

  static PaymentMethodStyle styleFor(String method) {
    final value = method.trim().toLowerCase();

    if (value.contains('visa')) {
      return const PaymentMethodStyle(
        Icons.credit_card_rounded,
        Color(0xFF1A1F71),
        'Visa',
      );
    }
    if (value.contains('master')) {
      return const PaymentMethodStyle(
        Icons.credit_card_rounded,
        Color(0xFFEB001B),
        'Mastercard',
      );
    }
    if (value.contains('amex') || value.contains('american express')) {
      return const PaymentMethodStyle(
        Icons.credit_card_rounded,
        Color(0xFF2E77BC),
        'Amex',
      );
    }
    if (value.contains('cash')) {
      return PaymentMethodStyle(
        Icons.payments_rounded,
        TransactionColors.greenBright,
        'Cash',
      );
    }
    if (value.contains('bank') || value.contains('transfer')) {
      return const PaymentMethodStyle(
        Icons.account_balance_rounded,
        Color(0xFF6366F1),
        'Bank transfer',
      );
    }
    if (value.contains('online')) {
      return const PaymentMethodStyle(
        Icons.language_rounded,
        Color(0xFF14B8A6),
        'Online',
      );
    }
    if (value.contains('card')) {
      return PaymentMethodStyle(
        Icons.credit_card_rounded,
        TransactionColors.blue,
        'Card',
      );
    }
    return PaymentMethodStyle(
      Icons.receipt_long_rounded,
      AppColors.textSecondary,
      method.isEmpty ? 'Other' : method,
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = styleFor(method);
    final tint = readableTint(style.color);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(style.icon, size: size * 0.55, color: tint),
    );
  }

  /// Brand colours like Visa navy vanish on a dark background, so lift them.
  static Color readableTint(Color color) {
    if (!AppColors.isDark) return color;
    return Color.lerp(color, Colors.white, 0.35) ?? color;
  }
}

class PaymentMethodStyle {
  final IconData icon;
  final Color color;
  final String label;

  const PaymentMethodStyle(this.icon, this.color, this.label);
}
