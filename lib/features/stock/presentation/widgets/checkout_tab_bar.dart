import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

enum CheckoutTab {
  keypad('Keypad'),
  inventory('Inventory'),
  allProducts('All products');

  final String label;

  const CheckoutTab(this.label);
}

/// Segmented pill selector with a sliding indicator.
class CheckoutTabBar extends StatelessWidget {
  final CheckoutTab selected;
  final ValueChanged<CheckoutTab> onChanged;

  const CheckoutTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tabs = CheckoutTab.values;

    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CheckoutTokens.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CheckoutTokens.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / tabs.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                left: tabWidth * selected.index,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: CheckoutTokens.surfaceRaised,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: CheckoutTokens.borderStrong),
                    boxShadow: CheckoutTokens.shadow(blur: 10, y: 4),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final tab in tabs)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(tab),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: CheckoutTokens.text(
                              size: 13,
                              weight: tab == selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: tab == selected
                                  ? CheckoutTokens.strongText
                                  : CheckoutTokens.softText,
                            ),
                            child: Text(tab.label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
