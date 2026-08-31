import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Compact snapshot of the current basket shown under the keypad.
class CheckoutSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final String amount;
  final bool isError;

  const CheckoutSummaryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.amount,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CheckoutTokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CheckoutTokens.border),
        boxShadow: CheckoutTokens.shadow(blur: 18, y: 10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CheckoutTokens.text(
                    size: 14.5,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CheckoutTokens.text(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: isError
                        ? CheckoutTokens.danger
                        : CheckoutTokens.softText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: CheckoutTokens.text(
                  size: 22,
                  weight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                trailing,
                style: CheckoutTokens.text(
                  size: 11.5,
                  weight: FontWeight.w700,
                  color: CheckoutTokens.softText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
