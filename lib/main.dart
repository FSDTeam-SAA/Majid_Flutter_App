import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'app_ground_view.dart';
import 'core/network/api_service/token_meneger.dart';
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
  Get.put(StockController());
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'iMoScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF39FF14),
          brightness: Brightness.dark,
        ),
      ),
      home: FutureBuilder<bool>(
        future: TokenManager.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return snapshot.data == true
              ? const AppGroundView()
              : const OnboardingScreenView();
        },
      ),
    );
  }
}
