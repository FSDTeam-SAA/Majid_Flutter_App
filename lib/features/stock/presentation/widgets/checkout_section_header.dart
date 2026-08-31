import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Title bar for a checkout list section, optionally carrying the toggle that
/// reveals the search field.
class CheckoutSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSearchTap;
  final bool isSearchOpen;

  const CheckoutSectionHeader({
    super.key,
    required this.title,
    this.onSearchTap,
    this.isSearchOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: CheckoutTokens.accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: CheckoutTokens.text(size: 15, weight: FontWeight.w800),
        ),
        const Spacer(),
        if (onSearchTap != null && !isSearchOpen)
          GestureDetector(
            onTap: onSearchTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: CheckoutTokens.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CheckoutTokens.border),
              ),
              child: Icon(
                Icons.search_rounded,
                size: 18,
                color: CheckoutTokens.softText,
              ),
            ),
          ),
      ],
    );
  }
}
