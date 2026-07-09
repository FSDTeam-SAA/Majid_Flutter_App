import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../../../core/animation/app_motion.dart';
import '../../../../app_ground_view.dart';
import '../../../../core/network/api_service/token_meneger.dart';
import '../../../../core/utils/colors.dart';
import '../../../auth/presentation/pages/login_screen_view.dart';
import 'onboarding_screen_view.dart';

class SplashScreenView extends StatefulWidget {
  const SplashScreenView({super.key});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with SingleTickerProviderStateMixin {
  static const _minimumSplashDuration = Duration(milliseconds: 5200);
  static const _heroTag = 'imoscan-brand-mark';

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoFloat;
  late final Animation<double> _textOpacity;
  late final Animation<double> _haloScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.splash,
    )..forward();

    _logoScale = Tween<double>(begin: 0.76, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.56, curve: AppMotion.easeOutExpo),
      ),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.34, curve: AppMotion.easeOutCubic),
      ),
    );
    _logoFloat = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.62, curve: AppMotion.easeOutExpo),
      ),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.34, 0.78, curve: AppMotion.easeOutCubic),
      ),
    );
    _haloScale = Tween<double>(begin: 0.82, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.74, curve: AppMotion.easeOutCubic),
      ),
    );

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
      () =>
          isLoggedIn
              ? const AppGroundView()
              : hasSeenOnboarding
              ? const LoginScreenView()
              : const OnboardingScreenView(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.translate(
                        offset: Offset(0, _logoFloat.value),
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: _haloScale.value,
                                child: Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.primary.withValues(
                                          alpha: 0.34,
                                        ),
                                        AppColors.primary.withValues(
                                          alpha: 0.04,
                                        ),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.62, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              Transform.scale(
                                scale: _logoScale.value,
                                child: Container(
                                  width: 118,
                                  height: 118,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground.withValues(
                                      alpha: AppColors.isDark ? 0.88 : 0.94,
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: AppColors.isDark ? 0.44 : 0.28,
                                      ),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: AppColors.isDark
                                              ? 0.22
                                              : 0.08,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: Hero(
                                    tag: _heroTag,
                                    child:
                                        Image.asset(
                                          'assets/images/imoscan_logo.png',
                                          fit: BoxFit.contain,
                                        )
                                        .animate(
                                          onPlay: (controller) =>
                                              controller.repeat(reverse: true),
                                          delay: const Duration(
                                            milliseconds: 1500,
                                          ),
                                        )
                                        .scaleXY(
                                          begin: 1,
                                          end: 1.07,
                                          duration: const Duration(
                                            milliseconds: 1400,
                                          ),
                                          curve: Curves.easeInOut,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 40,
                        child: _controller.value < 0.34
                            ? null
                            : Opacity(
                                opacity: _textOpacity.value,
                                child: AnimatedTextKit(
                                  isRepeatingAnimation: false,
                                  totalRepeatCount: 1,
                                  displayFullTextOnTap: true,
                                  animatedTexts: [
                                    WavyAnimatedText(
                                      'iMoScan',
                                      textStyle: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                      speed: const Duration(milliseconds: 280),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 42,
                        child: _controller.value < 0.34
                            ? null
                            : Opacity(
                                opacity: _textOpacity.value,
                                child: AnimatedTextKit(
                                  isRepeatingAnimation: false,
                                  totalRepeatCount: 1,
                                  displayFullTextOnTap: true,
                                  animatedTexts: [
                                    WavyAnimatedText(
                                      'Scan smarter. Sell with confidence.',
                                      textAlign: TextAlign.center,
                                      textStyle: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                      speed: const Duration(milliseconds: 120),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 34),
                      SizedBox(
                        width: 120,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            backgroundColor: AppColors.fieldBorder.withValues(
                              alpha: 0.4,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(),
                          ).shimmer(
                            duration: const Duration(milliseconds: 1200),
                            color: AppColors.surfaceForeground.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
