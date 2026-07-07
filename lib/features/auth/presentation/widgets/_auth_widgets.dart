import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/gradient_scaffold.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.fieldBorder),
          borderRadius: BorderRadius.circular(10),
          color: AppColors.fieldBackground,
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.textPrimary,
          size: 16,
        ),
      ),
    );
  }
}

class ImoscanTitle extends StatelessWidget {
  final double width;
  final double height;
  final Alignment alignment;

  const ImoscanTitle({
    super.key,
    this.width = 170,
    this.height = 44,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/icon.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: alignment,
    );
  }
}

class AuthLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const AuthLink({
    super.key,
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPageScaffold extends StatelessWidget {
  final Widget child;

  const AuthPageScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
