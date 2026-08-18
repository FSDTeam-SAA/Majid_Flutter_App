import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_ground_view.dart';
import '../../../../core/network/api_service/token_meneger.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_success_tick_animation.dart';
import '../../../auth/presentation/pages/login_screen_view.dart';
import 'onboarding_screen_view.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView> {
  static const _minimumSplashDuration = Duration(milliseconds: 5200);
  static const _heroTag = 'imoscan-brand-mark';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait([
      TokenManager.isLoggedIn(),
      TokenManager.hasSeenOnboarding(),
      Future<void>.delayed(_minimumSplashDuration),
    ]);
    final isLoggedIn = results.first as bool;
    final hasSeenOnboarding = results[1] as bool;

    if (!mounted) return;

    Get.offAll(
      () => isLoggedIn
          ? const AppGroundView()
          : hasSeenOnboarding
          ? const LoginScreenView()
          : const OnboardingScreenView(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: _heroTag,
                    child: const AppSuccessTickAnimation(size: 190),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
