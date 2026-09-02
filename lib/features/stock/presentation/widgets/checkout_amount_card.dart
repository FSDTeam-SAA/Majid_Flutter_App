import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Calculator readout from the mockup: the running expression above, the
/// result in large type, and the Note action beside it.
class CheckoutAmountCard extends StatelessWidget {
  final String amountText;
  final String expressionText;
  final bool showExpression;
  final bool hasAmount;
  final VoidCallback onClear;
  final VoidCallback onNote;

  const CheckoutAmountCard({
    super.key,
    required this.amountText,
    required this.expressionText,
    required this.showExpression,
    required this.hasAmount,
    required this.onClear,
    required this.onNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      decoration: BoxDecoration(
        color: CheckoutTokens.keySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CheckoutTokens.keyEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 26,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      showExpression ? expressionText : '',
                      maxLines: 1,
                      style: CheckoutTokens.text(
                        size: 14.5,
                        weight: FontWeight.w500,
                        color: CheckoutTokens.expressionInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: CheckoutTokens.softText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amountText,
                    maxLines: 1,
                    style: CheckoutTokens.text(
                      size: 48,
                      weight: FontWeight.w700,
                      color: hasAmount
                          ? CheckoutTokens.strongText
                          : CheckoutTokens.ghostText,
                      letterSpacing: -1.4,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _NoteButton(onTap: onNote),
            ],
          ),
        ],
      ),
    );
  }
}

/// Names the manually calculated lines before they reach the review screen.
class _NoteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NoteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: CheckoutTokens.keySurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CheckoutTokens.keyEdge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: CheckoutTokens.strongText,
              ),
              const SizedBox(height: 3),
              Text(
                'Note',
                style: CheckoutTokens.text(
                  size: 11.5,
                  weight: FontWeight.w600,
                  color: CheckoutTokens.strongText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
