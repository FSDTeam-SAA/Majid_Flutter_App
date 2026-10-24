import 'package:flutter/material.dart';

/// The supplied Score+ wordmark, framed to hide the photo's white margins.
class ScorePlusLogo extends StatelessWidget {
  const ScorePlusLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRect(
        child: OverflowBox(
          maxWidth: 50,
          maxHeight: 25,
          child: Image.asset(
            'assets/images/score_plus_logo.jpeg',
            width: 50,
            height: 25,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
