import 'package:flutter/material.dart';
import '../utils/colors.dart';

class GradientScaffold extends StatelessWidget {
  final Widget child;

  const GradientScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1F2D), Color(0xFF060E0B)],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
