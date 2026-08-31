import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Square, softly elevated icon button used across the checkout header.
class CheckoutIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool isAccent;

  const CheckoutIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isAccent
                ? CheckoutTokens.accentSoft
                : CheckoutTokens.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isAccent
                  ? CheckoutTokens.accent.withValues(alpha: 0.35)
                  : CheckoutTokens.border,
            ),
            boxShadow: CheckoutTokens.shadow(blur: 14, y: 6),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isAccent ? CheckoutTokens.accent : CheckoutTokens.strongText,
          ),
        ),
      ),
    );
  }
}
