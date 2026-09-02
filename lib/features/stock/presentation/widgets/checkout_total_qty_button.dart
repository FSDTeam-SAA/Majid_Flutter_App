import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Replaces the old Pay/Charge control on the keypad. It summarises how many
/// units have been keyed in and opens the review screen.
class CheckoutTotalQtyButton extends StatelessWidget {
  final int quantity;
  final VoidCallback onTap;

  const CheckoutTotalQtyButton({
    super.key,
    required this.quantity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: CheckoutTokens.limeGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                'Total Qty $quantity',
                style: CheckoutTokens.text(
                  size: 17,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
