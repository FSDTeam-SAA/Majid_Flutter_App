import 'package:flutter/material.dart';

import '../../domain/entities/ready_order.dart';
import '../theme/checkout_tokens.dart';

/// Finished repairs waiting to be collected and paid for, mirroring the web
/// checkout's "Orders Ready for Collection" panel.
class ReadyOrdersCard extends StatelessWidget {
  final List<ReadyOrder> orders;
  final VoidCallback onToggleVisibility;
  final bool isSheetVisible;

  const ReadyOrdersCard({
    super.key,
    required this.orders,
    required this.onToggleVisibility,
    required this.isSheetVisible,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: CheckoutTokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: CheckoutTokens.border),
        boxShadow: CheckoutTokens.shadow(blur: 16, y: 8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: CheckoutTokens.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.build_rounded,
                  size: 15,
                  color: CheckoutTokens.accent,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Orders Ready for Collection',
                  maxLines: 2,
                  style: CheckoutTokens.text(size: 14, weight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleVisibility,
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CheckoutTokens.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: CheckoutTokens.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      isSheetVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: CheckoutTokens.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
