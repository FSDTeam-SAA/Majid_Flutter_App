import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Rounded search field for filtering products and categories.
class CheckoutSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  const CheckoutSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: CheckoutTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CheckoutTokens.border),
        boxShadow: CheckoutTokens.shadow(blur: 16, y: 8),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: autofocus,
        cursorColor: CheckoutTokens.accent,
        style: CheckoutTokens.text(size: 14, weight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Search products, brands, IMEI',
          hintStyle: CheckoutTokens.text(
            size: 13.5,
            weight: FontWeight.w500,
            color: CheckoutTokens.softText,
          ),
          suffixIcon: GestureDetector(
            onTap: onClear,
            child: Icon(
              Icons.close_rounded,
              color: CheckoutTokens.softText,
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
