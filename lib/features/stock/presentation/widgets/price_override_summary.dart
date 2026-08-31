import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Running tally of the prices edited during this checkout.
class PriceOverrideSummary extends StatelessWidget {
  final int count;
  final String totalLabel;
  final VoidCallback onReset;

  const PriceOverrideSummary({
    super.key,
    required this.count,
    required this.totalLabel,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
      decoration: BoxDecoration(
        color: CheckoutTokens.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CheckoutTokens.accent.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.sell_rounded, size: 15, color: CheckoutTokens.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count == 1
                  ? '1 price edited · $totalLabel off'
                  : '$count prices edited · $totalLabel off',
              style: CheckoutTokens.text(
                size: 12.5,
                weight: FontWeight.w800,
                color: CheckoutTokens.accent,
              ),
            ),
          ),
          GestureDetector(
            onTap: onReset,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                'Reset all',
                style: CheckoutTokens.text(
                  size: 12,
                  weight: FontWeight.w800,
                  color: CheckoutTokens.softText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
