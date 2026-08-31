import 'package:flutter/material.dart';

import '../../domain/entities/inventory_item.dart';
import '../theme/checkout_tokens.dart';

/// Single product line with a quick add-to-basket action.
class CheckoutProductRow extends StatelessWidget {
  final InventoryItem item;
  final String priceLabel;

  /// Set only when the price has been overridden at checkout.
  final String? originalPriceLabel;
  final String? discountLabel;
  final VoidCallback onAdd;
  final VoidCallback onEditPrice;

  const CheckoutProductRow({
    super.key,
    required this.item,
    required this.priceLabel,
    required this.onAdd,
    required this.onEditPrice,
    this.originalPriceLabel,
    this.discountLabel,
  });

  @override
  Widget build(BuildContext context) {
    final meta = [
      item.brand,
      item.storage,
      item.color,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CheckoutTokens.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CheckoutTokens.border),
        boxShadow: CheckoutTokens.shadow(blur: 14, y: 8),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: CheckoutTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.phone_iphone_rounded,
              color: CheckoutTokens.softText,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CheckoutTokens.text(
                    size: 14.5,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meta.isEmpty ? 'Ready to add' : meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CheckoutTokens.text(
                    size: 12,
                    weight: FontWeight.w600,
                    color: CheckoutTokens.softText,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onEditPrice,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Text(
                        priceLabel,
                        style: CheckoutTokens.text(
                          size: 15.5,
                          weight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: originalPriceLabel == null
                              ? CheckoutTokens.strongText
                              : CheckoutTokens.accent,
                        ),
                      ),
                      if (originalPriceLabel != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          originalPriceLabel!,
                          style: CheckoutTokens.text(
                            size: 12,
                            weight: FontWeight.w600,
                            color: CheckoutTokens.softText,
                          ).copyWith(decoration: TextDecoration.lineThrough),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Icon(
                        Icons.edit_rounded,
                        size: 13,
                        color: CheckoutTokens.softText,
                      ),
                    ],
                  ),
                ),
                if (discountLabel != null) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: CheckoutTokens.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      discountLabel!,
                      style: CheckoutTokens.text(
                        size: 10.5,
                        weight: FontWeight.w800,
                        color: CheckoutTokens.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(15),
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: CheckoutTokens.accentGradient,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: CheckoutTokens.glow(
                    CheckoutTokens.accent,
                    blur: 14,
                    y: 6,
                  ),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: CheckoutTokens.onAccent,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
