import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Category tile used on the Shortcuts tab.
class CheckoutShortcutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? subtitleColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const CheckoutShortcutCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.inventory_2_rounded,
    this.backgroundColor,
    this.iconBackgroundColor,
    this.iconColor,
    this.textColor,
    this.subtitleColor,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? CheckoutTokens.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor ?? CheckoutTokens.border),
            boxShadow: boxShadow ?? CheckoutTokens.shadow(blur: 16, y: 9),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBackgroundColor ?? CheckoutTokens.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? CheckoutTokens.accent,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CheckoutTokens.text(
                    size: 15.5,
                    weight: FontWeight.w800,
                    color: textColor,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: CheckoutTokens.text(
                    size: 12,
                    weight: FontWeight.w600,
                    color: subtitleColor ?? CheckoutTokens.softText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
