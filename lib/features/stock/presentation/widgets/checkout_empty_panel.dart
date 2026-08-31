import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Placeholder shown when a checkout list has nothing to display.
class CheckoutEmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CheckoutEmptyPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: CheckoutTokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CheckoutTokens.border),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: CheckoutTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 24, color: CheckoutTokens.softText),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CheckoutTokens.text(size: 15.5, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: CheckoutTokens.text(
              size: 12.5,
              weight: FontWeight.w500,
              color: CheckoutTokens.softText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
