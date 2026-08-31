import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/token_meneger.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/controller/auth_controller.dart';
import '../../../auth/presentation/pages/login_screen_view.dart';
import '../controller/profile_controller.dart';
import '../widgets/currency_picker.dart';
import '../controller/profile_theme_controller.dart';
import '../widgets/profile_menu_item.dart';
import 'business_health_score_page.dart';
import 'edit_profile_page.dart';
import 'invoice_logo_settings_page.dart';
import 'payment_history_page.dart';
import 'shopkeeper_id_card_page.dart';
import 'upgrade_plan_page.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../invoice/presentation/pages/invoice_page.dart';
import '../../../staff/presentation/pages/staff_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';

class ProfilePageView extends StatefulWidget {
  const ProfilePageView({super.key});

  @override
  State<ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<ProfilePageView>
    with WidgetsBindingObserver {
  late final ProfileController _profileCtrl;
  late final ProfileThemeController _themeCtrl;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _profileCtrl = Get.find<ProfileController>();
    _themeCtrl = Get.isRegistered<ProfileThemeController>()
        ? Get.find<ProfileThemeController>()
        : Get.put(ProfileThemeController());
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await TokenManager.getRole();
    if (mounted) setState(() => _isStaff = role == 'staff');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _profileCtrl.hasNoProfile) {
      _profileCtrl.fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = _profileCtrl;
    final themeCtrl = _themeCtrl;

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

                if (profileCtrl.hasNoProfile) {
                  final sessionExpired = profileCtrl.isSessionExpired.value;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          sessionExpired
                              ? Icons.lock_clock_outlined
                              : Icons.cloud_off_outlined,
                          color: palette.textSecondary,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          sessionExpired
                              ? 'Your session has expired'
                              : 'Could not load profile',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: sessionExpired
                              ? () async {
                                  await Get.find<AuthController>().logout();
                                  Get.offAll(() => const LoginScreenView());
                                }
                              : profileCtrl.fetchProfile,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: sessionExpired
                                  ? palette.dangerColor
                                  : palette.primaryColor,
                            ),
                            foregroundColor: sessionExpired
                                ? palette.dangerColor
                                : palette.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            sessionExpired ? 'Log in again' : 'Retry',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: palette.primaryColor,
                  backgroundColor: palette.surfaceColor,
                  onRefresh: profileCtrl.fetchProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        _buildThemeButton(themeCtrl, palette),
                        SizedBox(height: 24),
                        ProfileMenuItem(
                          label: 'Currency symbol',
                          value:
                              ProfileController.currencyNames[profileCtrl
                                  .currencyCode
                                  .toUpperCase()] ??
                              profileCtrl.currencyCode,
                          onTap: () => showCurrencyPicker(context, palette),
                          backgroundColor: palette.surfaceColor,
                          borderColor: palette.surfaceBorderColor,
                          textColor: palette.textPrimary,
                          iconColor: palette.textSecondary,
                        ),
                        SizedBox(height: 8),
                        _buildSection(null, [
                          (
                            'Invoice',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => InvoicePage()),
                            ),
                          ),
                          (
                            'Invoice & Receipt Logo',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InvoiceLogoSettingsPage(),
                              ),
                            ),
                          ),
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
                          (
                            'Customers',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerPage(),
                              ),
                            ),
                          ),
                          (
                            'Suppliers',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SupplierPage(),
                              ),
                            ),
                          ),
                          // Staff Management is shopkeeper-only — staff
                          // accounts can add/delete other staff otherwise.
                          if (!_isStaff)
                            (
                              'Staff Management',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => StaffPage()),
                              ),
                            ),
                        ], palette),
                        SizedBox(height: 24),
                        // Subscription/billing is shopkeeper-only.
                        if (!_isStaff) ...[
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
                        ],
                        _buildSection('Support', [
                          (
                            'Help Center',
                            () => _showInfo(
                              context,
                              'Help Center is coming soon.',
                            ),
                          ),
                          (
                            'About App',
                            () => _showInfo(
                              context,
                              'iMoScan helps verify devices, manage checkout, repairs, and invoices.',
                            ),
                          ),
                        ], palette),
                        SizedBox(height: 32),
                        _buildLogoutBtn(palette),
                        SizedBox(height: 100),
                      ],
                    ),
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
    ProfileThemeController themeCtrl,
    ProfileThemePalette palette,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: palette.surfaceBorderColor),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              palette.surfaceColor.withValues(alpha: 0.96),
              palette.backgroundColor,
            ),
            Color.alphaBlend(
              palette.primaryColor.withValues(alpha: 0.14),
              palette.backgroundColor,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: palette.backgroundColor.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: palette.gradient,
                border: Border.all(
                  color: palette.primaryColor.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                palette.brightness == Brightness.dark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                color: palette.primaryColor,
                size: 18,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile theme',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Toggle Theme',
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.backgroundColor.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: palette.surfaceBorderColor.withValues(alpha: 0.9),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildThemeToggleChip(
                    palette: palette,
                    label: 'Dark',
                    icon: Icons.nights_stay_rounded,
                    selected: themeCtrl.isSelected(ProfileThemeOption.midnight),
                    onTap: () =>
                        themeCtrl.setTheme(ProfileThemeOption.midnight),
                  ),
                  SizedBox(width: 6),
                  _buildThemeToggleChip(
                    palette: palette,
                    label: 'Light',
                    icon: Icons.wb_sunny_rounded,
                    selected: themeCtrl.isSelected(ProfileThemeOption.sunrise),
                    onTap: () => themeCtrl.setTheme(ProfileThemeOption.sunrise),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggleChip({
    required ProfileThemePalette palette,
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? palette.primaryColor
                : palette.surfaceColor.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? palette.primaryColor
                  : palette.surfaceBorderColor.withValues(alpha: 0.75),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? palette.onPrimaryColor
                    : palette.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? palette.onPrimaryColor
                      : palette.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
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
    String? title,
    List<(String, VoidCallback)> items,
    ProfileThemePalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10),
        ],
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

  Widget _buildLogoutBtn(ProfileThemePalette palette) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () async {
          await Get.find<AuthController>().logout();
          Get.offAll(() => const LoginScreenView());
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
