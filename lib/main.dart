import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/animation/app_motion.dart';
import 'core/animation/app_page_transition.dart';
import 'core/network/api_service/session_events.dart';
import 'core/network/api_service/token_meneger.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/utils/colors.dart';
import 'features/auth/presentation/controller/auth_controller.dart';
import 'features/auth/presentation/pages/login_screen_view.dart';
import 'features/home/presentation/controller/home_controller.dart';
import 'features/onboarding/presentation/pages/splash_screen_view.dart';
import 'core/utils/shop_logo_settings.dart';
import 'features/profile/presentation/controller/profile_controller.dart';
import 'features/stock/presentation/controller/stock_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.clearPersistedSessionOnFreshInstall();
  await ShopLogoSettings.load();
  Get.put(AuthController());
  Get.put(ProfileThemeController());
  Get.lazyPut(() => HomeController(), fenix: true);
  Get.lazyPut(() => ProfileController(), fenix: true);
  Get.lazyPut(() => StockController(), fenix: true);
  SessionEvents.onSessionExpired = () =>
      Get.offAll(() => const LoginScreenView());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ProfileThemeController>();

    return Obx(() {
      final palette = themeCtrl.palette;

      return GetMaterialApp(
        title: 'iMoScan',
        debugShowCheckedModeBanner: false,
        transitionDuration: AppMotion.route,
        customTransition: AppPageTransitions.getx,
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: palette.primaryColor,
            brightness: palette.brightness,
          ),
          pageTransitionsTheme: AppPageTransitions.theme,
        ),
        home: const SplashScreenView(),
      );
    });
  }
}
