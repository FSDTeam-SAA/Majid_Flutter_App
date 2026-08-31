import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Calculator readout: the running expression on a thin header line, with the
/// result below it in large type. Modelled on the client's reference.
class CheckoutAmountCard extends StatelessWidget {
  final String amountText;
  final String expressionText;
  final bool showExpression;
  final bool hasAmount;
  final VoidCallback onClear;

  const CheckoutAmountCard({
    super.key,
    required this.amountText,
    required this.expressionText,
    required this.showExpression,
    required this.hasAmount,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: CheckoutTokens.readoutSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Starts at the left like the reference, but keeps the
                        // newest keystroke in view once it overflows.
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                showExpression ? expressionText : '',
                                maxLines: 1,
                                style: CheckoutTokens.text(
                                  size: 15,
                                  weight: FontWeight.w500,
                                  color: CheckoutTokens.softText,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onClear,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: CheckoutTokens.softText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: CheckoutTokens.readoutDivider),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 30, 18, 34),
            child: SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  amountText,
                  maxLines: 1,
                  style: CheckoutTokens.text(
                    size: 46,
                    weight: FontWeight.w600,
                    color: hasAmount
                        ? CheckoutTokens.readout
                        : CheckoutTokens.ghostText,
                    letterSpacing: -1.4,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
