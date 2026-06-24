import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/controller/auth_controller.dart';
import '../../../onboarding/presentation/pages/onboarding_screen_view.dart';
import '../controller/profile_controller.dart';
import '../controller/profile_theme_controller.dart';
import '../widgets/profile_menu_item.dart';
import 'business_health_score_page.dart';
import 'edit_profile_page.dart';
import 'payment_history_page.dart';
import 'shopkeeper_id_card_page.dart';
import 'upgrade_plan_page.dart';

class ProfilePageView extends StatelessWidget {
  const ProfilePageView({super.key});

  ProfileThemeController _resolveThemeController() {
    if (Get.isRegistered<ProfileThemeController>()) {
      return Get.find<ProfileThemeController>();
    }

    return Get.put(ProfileThemeController());
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    final themeCtrl = _resolveThemeController();

    return Obx(() {
      final palette = themeCtrl.palette;

      return GradientScaffold(
        backgroundColor: palette.backgroundColor,
        gradient: palette.gradient,
        child: Column(
          children: [
            AppHeader(
              title: 'Profile',
              buttonBackgroundColor: palette.surfaceColor,
              buttonBorderColor: palette.surfaceBorderColor,
              iconColor: palette.textPrimary,
              textColor: palette.textPrimary,
            ),
            Expanded(
              child: Obx(() {
                if (profileCtrl.isLoading.value) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: palette.primaryColor,
                    ),
                  );
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      _buildAvatar(profileCtrl, palette),
                      SizedBox(height: 14),
                      Obx(
                        () => Text(
                          profileCtrl.fullName.isNotEmpty
                              ? profileCtrl.fullName
                              : 'User',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      Obx(
                        () => Text(
                          profileCtrl.email,
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      _buildCreditsRow(profileCtrl, context, palette),
                      SizedBox(height: 16),
                      _buildThemeButton(context, themeCtrl, palette),
                      SizedBox(height: 32),
                      _buildSection('Account', [
                        (
                          'Shopkeeper Id Card',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopkeeperIdCardPage(),
                            ),
                          ),
                        ),
                        (
                          'Account Information',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProfilePage(),
                            ),
                          ),
                        ),
                        (
                          'Business Health Score',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BusinessHealthScorePage(),
                            ),
                          ),
                        ),
                      ], palette),
                      SizedBox(height: 24),
                      _buildSection('Subscription', [
                        (
                          'Upgrade Plan',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UpgradePlanPage(),
                            ),
                          ),
                        ),
                        (
                          'Payment History',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentHistoryPage(),
                            ),
                          ),
                        ),
                      ], palette),
                      SizedBox(height: 24),
                      _buildSection('Support', [
                        (
                          'Help Center',
                          () =>
                              _showInfo(context, 'Help Center is coming soon.'),
                        ),
                        (
                          'About App',
                          () => _showInfo(
                            context,
                            'iMoScan helps verify devices, manage stock, repairs, and invoices.',
                          ),
                        ),
                      ], palette),
                      SizedBox(height: 32),
                      _buildLogoutBtn(palette),
                      SizedBox(height: 100),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildThemeButton(
    BuildContext context,
    ProfileThemeController themeCtrl,
    ProfileThemePalette palette,
  ) {
    return OutlinedButton.icon(
      onPressed: () => _showThemePicker(context, themeCtrl, palette),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: palette.surfaceBorderColor),
        backgroundColor: palette.surfaceColor,
        foregroundColor: palette.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      icon: Icon(
        Icons.color_lens_outlined,
        color: palette.primaryColor,
        size: 18,
      ),
      label: Text(
        'Change Theme',
        style: TextStyle(
          color: palette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    ProfileThemeController themeCtrl,
    ProfileThemePalette palette,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Obx(() {
          final activePalette = themeCtrl.palette;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose profile theme',
                    style: TextStyle(
                      color: activePalette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Switch the look of your profile screen anytime.',
                    style: TextStyle(
                      color: activePalette.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 18),
                  ...ProfileThemeOption.values.map(
                    (option) => Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: _buildThemeOption(sheetContext, themeCtrl, option),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildAvatar(ProfileController ctrl, ProfileThemePalette palette) {
    return Obx(() {
      final url = ctrl.imageUrl;
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: palette.surfaceBorderColor, width: 2),
        ),
        child: ClipOval(
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.person, color: palette.textPrimary, size: 50),
                )
              : Icon(Icons.person, color: palette.textPrimary, size: 50),
        ),
      );
    });
  }

  Widget _buildCreditsRow(
    ProfileController ctrl,
    BuildContext context,
    ProfileThemePalette palette,
  ) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Your credits: ${ctrl.balance.toStringAsFixed(0)}',
            style: TextStyle(color: palette.textPrimary, fontSize: 14),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UpgradePlanPage()),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: palette.primaryColor),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Upgrade',
                style: TextStyle(
                  color: palette.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<(String, VoidCallback)> items,
    ProfileThemePalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ProfileMenuItem(
              label: item.$1,
              onTap: item.$2,
              backgroundColor: palette.surfaceColor,
              borderColor: palette.surfaceBorderColor,
              textColor: palette.textPrimary,
              iconColor: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildThemeOption(
    BuildContext context,
    ProfileThemeController themeCtrl,
    ProfileThemeOption option,
  ) {
    final optionPalette = themeCtrl.paletteFor(option);
    final isSelected = themeCtrl.isSelected(option);

    return InkWell(
      onTap: () async {
        await themeCtrl.setTheme(option);
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: optionPalette.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? optionPalette.primaryColor
                : optionPalette.surfaceBorderColor,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: optionPalette.gradient,
                shape: BoxShape.circle,
                border: Border.all(color: optionPalette.surfaceBorderColor),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    optionPalette.title,
                    style: TextStyle(
                      color: optionPalette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    optionPalette.subtitle,
                    style: TextStyle(
                      color: optionPalette.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected
                  ? optionPalette.primaryColor
                  : optionPalette.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutBtn(ProfileThemePalette palette) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await Get.find<AuthController>().logout();
          Get.offAll(() => OnboardingScreenView());
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.dangerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          'Log out',
          style: TextStyle(
            color: palette.dangerColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
