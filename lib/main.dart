import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_ground_view.dart';
import 'core/network/api_service/token_meneger.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/utils/colors.dart';
import 'features/auth/presentation/controller/auth_controller.dart';
import 'features/home/presentation/controller/home_controller.dart';
import 'features/onboarding/presentation/pages/onboarding_screen_view.dart';
import 'features/profile/presentation/controller/profile_controller.dart';
import 'features/stock/presentation/controller/stock_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController());
  Get.put(HomeController());
  Get.put(ProfileController());
  Get.put(ProfileThemeController());
  Get.put(StockController());
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
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.background,
          colorScheme: ColorScheme.fromSeed(
            seedColor: palette.primaryColor,
            brightness: palette.brightness,
          ),
        ),
        home: FutureBuilder<bool>(
          future: TokenManager.isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return snapshot.data == true
                ? AppGroundView()
                : OnboardingScreenView();
          },
        ),
      );
    });
  }
}
