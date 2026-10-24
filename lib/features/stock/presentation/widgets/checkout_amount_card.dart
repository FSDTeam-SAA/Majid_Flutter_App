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
  final bool compact;

  const CheckoutAmountCard({
    super.key,
    required this.amountText,
    required this.expressionText,
    required this.showExpression,
    required this.hasAmount,
    required this.onClear,
    required this.onNote,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 12, compact ? 8 : 14),
      decoration: BoxDecoration(
        color: CheckoutTokens.keySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: CheckoutTokens.keyEdge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 20 : 26,
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
          SizedBox(height: compact ? 4 : 10),
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
                      size: compact ? 36 : 48,
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
              _NoteButton(onTap: onNote, compact: compact),
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
  final bool compact;

  const _NoteButton({required this.onTap, this.compact = false});

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
          child: Flex(
            direction: compact ? Axis.horizontal : Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                size: 18,
                color: CheckoutTokens.strongText,
              ),
              SizedBox(height: compact ? 0 : 3, width: compact ? 5 : 0),
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
