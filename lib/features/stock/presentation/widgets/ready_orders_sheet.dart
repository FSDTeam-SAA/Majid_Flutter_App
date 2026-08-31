import 'package:flutter/material.dart';

import '../../domain/entities/ready_order.dart';
import '../theme/checkout_tokens.dart';
import 'checkout_icon_button.dart';

/// Lists the finished repairs so one can be pulled into checkout and charged.
/// Returns the picked order, or `null` when dismissed.
Future<ReadyOrder?> showReadyOrdersSheet({
  required BuildContext context,
  required List<ReadyOrder> orders,
  required String Function(num value) formatCurrency,
}) {
  return showModalBottomSheet<ReadyOrder>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CheckoutTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) =>
        _ReadyOrdersSheet(orders: orders, formatCurrency: formatCurrency),
  );
}

class _ReadyOrdersSheet extends StatelessWidget {
  final List<ReadyOrder> orders;
  final String Function(num value) formatCurrency;

  const _ReadyOrdersSheet({required this.orders, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          20 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: CheckoutTokens.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for collection',
                        style: CheckoutTokens.text(
                          size: 18,
                          weight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Completed by technicians. Tap a row to view it in '
                        'checkout or use Charge directly.',
                        style: CheckoutTokens.text(
                          size: 12.5,
                          weight: FontWeight.w500,
                          color: CheckoutTokens.softText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CheckoutIconButton(
                  icon: Icons.close_rounded,
                  size: 38,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (orders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: CheckoutTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: CheckoutTokens.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 34,
                      color: CheckoutTokens.softText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No ready orders yet',
                      textAlign: TextAlign.center,
                      style: CheckoutTokens.text(
                        size: 15,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Completed repair orders will appear here and you will be able to charge them from this list.',
                      textAlign: TextAlign.center,
                      style: CheckoutTokens.text(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: CheckoutTokens.softText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ReadyOrderRow(
                    order: orders[index],
                    priceLabel: formatCurrency(orders[index].price),
                    onTap: () => Navigator.pop(context, orders[index]),
                    onCharge: () => Navigator.pop(context, orders[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReadyOrderRow extends StatelessWidget {
  final ReadyOrder order;
  final String priceLabel;
  final VoidCallback onTap;
  final VoidCallback onCharge;

  const _ReadyOrderRow({
    required this.order,
    required this.priceLabel,
    required this.onTap,
    required this.onCharge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: CheckoutTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CheckoutTokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: CheckoutTokens.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  order.initials,
                  style: CheckoutTokens.text(
                    size: 13,
                    weight: FontWeight.w800,
                    color: CheckoutTokens.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.deviceModel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CheckoutTokens.text(
                        size: 14,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.customerName} · ${order.reference}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CheckoutTokens.text(
                        size: 11.5,
                        weight: FontWeight.w600,
                        color: CheckoutTokens.softText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceLabel,
                    style: CheckoutTokens.text(
                      size: 15,
                      weight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onCharge,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: CheckoutTokens.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Charge',
                        style: CheckoutTokens.text(
                          size: 11.5,
                          weight: FontWeight.w800,
                          color: CheckoutTokens.onAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
