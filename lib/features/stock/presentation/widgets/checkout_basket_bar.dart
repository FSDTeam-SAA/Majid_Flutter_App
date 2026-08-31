import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Sticky bottom bar summarising the basket and opening it.
class CheckoutBasketBar extends StatelessWidget {
  final int itemCount;
  final String totalLabel;
  final bool isLoading;
  final VoidCallback onTap;

  const CheckoutBasketBar({
    super.key,
    required this.itemCount,
    required this.totalLabel,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: CheckoutTokens.ctaBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: CheckoutTokens.shadow(blur: 24, y: 12),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CheckoutTokens.ctaForeground.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_basket_rounded,
                  size: 17,
                  color: CheckoutTokens.ctaForeground,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLoading ? 'Loading basket' : 'View basket',
                    style: CheckoutTokens.text(
                      size: 14.5,
                      weight: FontWeight.w800,
                      color: CheckoutTokens.ctaForeground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading
                        ? 'Syncing items'
                        : '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                    style: CheckoutTokens.text(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: CheckoutTokens.ctaForeground.withValues(
                        alpha: 0.62,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CheckoutTokens.ctaForeground,
                  ),
                )
              else ...[
                Text(
                  totalLabel,
                  style: CheckoutTokens.text(
                    size: 17,
                    weight: FontWeight.w800,
                    color: CheckoutTokens.ctaForeground,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: CheckoutTokens.ctaForeground.withValues(alpha: 0.75),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
