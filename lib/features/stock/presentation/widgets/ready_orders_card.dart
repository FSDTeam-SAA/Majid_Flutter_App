import 'package:flutter/material.dart';

import '../../domain/entities/ready_order.dart';
import '../theme/checkout_tokens.dart';

/// Finished repairs waiting to be collected and paid for, mirroring the web
/// checkout's "Orders Ready for Collection" panel.
class ReadyOrdersCard extends StatelessWidget {
  final List<ReadyOrder> orders;
  final VoidCallback onToggleVisibility;

  const ReadyOrdersCard({
    super.key,
    required this.orders,
    required this.onToggleVisibility,
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
                  'Orders',
                  maxLines: 2,
                  style: CheckoutTokens.text(size: 14, weight: FontWeight.w800),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: orders.isEmpty
                        ? 'Orders'
                        : '${orders.length} orders awaiting collection',
                    onPressed: onToggleVisibility,
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: CheckoutTokens.accent,
                    ),
                  ),
                  if (orders.isNotEmpty)
                    Positioned(
                      right: 2,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        child: Text(
                          '${orders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
