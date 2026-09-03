import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Rounded search field for filtering products and categories.
class CheckoutSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool autofocus;

  /// Opens the barcode/IMEI scanner and fills the field with the result.
  /// Omitted where a scanner does not make sense for that search.
  final VoidCallback? onScan;

  const CheckoutSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    this.autofocus = false,
    this.onScan,
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
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onScan != null)
                GestureDetector(
                  onTap: onScan,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: CheckoutTokens.accent,
                      size: 20,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    Icons.close_rounded,
                    color: CheckoutTokens.softText,
                    size: 18,
                  ),
                ),
              ),
            ],
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
