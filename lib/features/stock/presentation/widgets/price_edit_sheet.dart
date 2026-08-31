import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/checkout_tokens.dart';
import 'checkout_icon_button.dart';

/// Lets the shopkeeper override a product's price at checkout time.
///
/// Returns the chosen price, or `null` when dismissed. Returning the original
/// price is how "reset" is expressed - the caller then drops its override.
Future<double?> showPriceEditSheet({
  required BuildContext context,
  required TextEditingController controller,
  required String itemName,
  required String currencySymbol,
  required double originalPrice,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CheckoutTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _PriceEditSheet(
      controller: controller,
      itemName: itemName,
      currencySymbol: currencySymbol,
      originalPrice: originalPrice,
    ),
  );
}

class _PriceEditSheet extends StatefulWidget {
  final TextEditingController controller;
  final String itemName;
  final String currencySymbol;
  final double originalPrice;

  const _PriceEditSheet({
    required this.controller,
    required this.itemName,
    required this.currencySymbol,
    required this.originalPrice,
  });

  @override
  State<_PriceEditSheet> createState() => _PriceEditSheetState();
}

class _PriceEditSheetState extends State<_PriceEditSheet> {
  double get _typed =>
      double.tryParse(widget.controller.text.trim()) ?? widget.originalPrice;

  double get _discount => widget.originalPrice - _typed;

  double get _discountPercent =>
      widget.originalPrice <= 0 ? 0 : _discount / widget.originalPrice * 100;

  String _money(double value) {
    final hasFraction = value % 1 != 0;
    return '${widget.currencySymbol}${value.toStringAsFixed(hasFraction ? 2 : 0)}';
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final hasDiscount = _discount.abs() >= 0.01;
    final isMarkup = _discount < 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + inset),
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
                      'Edit price',
                      style: CheckoutTokens.text(
                        size: 18,
                        weight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CheckoutTokens.text(
                        size: 12.5,
                        weight: FontWeight.w600,
                        color: CheckoutTokens.softText,
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
          TextField(
            controller: widget.controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() {}),
            cursorColor: CheckoutTokens.accent,
            style: CheckoutTokens.text(size: 26, weight: FontWeight.w800),
            decoration: InputDecoration(
              prefixText: '${widget.currencySymbol} ',
              prefixStyle: CheckoutTokens.text(
                size: 22,
                weight: FontWeight.w700,
                color: CheckoutTokens.softText,
              ),
              filled: true,
              fillColor: CheckoutTokens.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: CheckoutTokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: CheckoutTokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: CheckoutTokens.accent,
                  width: 1.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasDiscount
                  ? (isMarkup
                        ? CheckoutTokens.dangerSoft
                        : CheckoutTokens.accentSoft)
                  : CheckoutTokens.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  'Original ${_money(widget.originalPrice)}',
                  style: CheckoutTokens.text(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: CheckoutTokens.softText,
                  ),
                ),
                const Spacer(),
                Text(
                  !hasDiscount
                      ? 'No change'
                      : isMarkup
                      ? '${_money(_discount.abs())} extra'
                      : '${_money(_discount)} off · '
                            '${_discountPercent.toStringAsFixed(_discountPercent % 1 == 0 ? 0 : 1)}%',
                  style: CheckoutTokens.text(
                    size: 13,
                    weight: FontWeight.w800,
                    color: !hasDiscount
                        ? CheckoutTokens.softText
                        : (isMarkup
                              ? CheckoutTokens.danger
                              : CheckoutTokens.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, widget.originalPrice),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: CheckoutTokens.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: CheckoutTokens.text(
                        size: 15,
                        weight: FontWeight.w800,
                        color: CheckoutTokens.softText,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _typed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CheckoutTokens.ctaBackground,
                      foregroundColor: CheckoutTokens.ctaForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply price',
                      style: CheckoutTokens.text(
                        size: 15,
                        weight: FontWeight.w800,
                        color: CheckoutTokens.ctaForeground,
                      ),
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
