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
import 'shopkeeper_id_card_page.dart';
import '../../../customer/presentation/pages/customer_page.dart';
import '../../../invoice/presentation/pages/invoice_page.dart';
import '../../../staff/presentation/pages/staff_page.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../../legal/domain/legal_documents.dart';
import '../../../legal/presentation/pages/legal_document_page.dart';
import '../../../privacy/presentation/pages/privacy_permissions_page.dart';

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
                        SizedBox(height: 16),
                        // Owner name, then the brand name directly beneath it.
                        // No logo, avatar or email here: the client asked for
                        // both to come off this screen, and the email stays
                        // inside Account Information only.
                        _buildIdentity(profileCtrl, palette),
                        SizedBox(height: 16),
                        _buildThemeButton(themeCtrl, palette),
                        SizedBox(height: 22),
                        _buildSectionLabel('Business', palette),
                        SizedBox(height: 10),
                        ProfileMenuItem(
                          leadingIcon: Icons.payments_outlined,
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
                            Icons.description_outlined,
                            'Invoice',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => InvoicePage()),
                            ),
                          ),
                          (
                            Icons.image_outlined,
                            'Invoice & Receipt Logo',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InvoiceLogoSettingsPage(),
                              ),
                            ),
                          ),
                          (
                            Icons.badge_outlined,
                            'Shopkeeper Id Card',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ShopkeeperIdCardPage(),
                              ),
                            ),
                          ),
                          (
                            Icons.manage_accounts_outlined,
                            'Account Information',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProfilePage(),
                              ),
                            ),
                          ),
                          (
                            Icons.lock_outline_rounded,
                            'Privacy & Permissions',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPermissionsPage(),
                              ),
                            ),
                          ),
                          (
                            Icons.monitor_heart_outlined,
                            'Business Health Score',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessHealthScorePage(),
                              ),
                            ),
                          ),
                          (
                            Icons.people_outline_rounded,
                            'Customers',
                            // The owner always has full customer access; staff
                            // access is set per role in Staff Management.
                            _isStaff ? null : 'Owner: Full access',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CustomerPage(),
                              ),
                            ),
                          ),
                          (
                            Icons.local_shipping_outlined,
                            'Suppliers',
                            null,
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
                              Icons.groups_outlined,
                              'Staff Management',
                              null,
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => StaffPage()),
                              ),
                            ),
                        ], palette),
                        SizedBox(height: 22),
                        // Legal sits directly above Support, as specified.
                        _buildSection('Legal', [
                          (
                            Icons.gavel_outlined,
                            'Terms & Conditions',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LegalDocumentPage(
                                  document: LegalDocuments.terms,
                                ),
                              ),
                            ),
                          ),
                          (
                            Icons.privacy_tip_outlined,
                            'Privacy Policy',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LegalDocumentPage(
                                  document: LegalDocuments.privacyPolicy,
                                ),
                              ),
                            ),
                          ),
                          (
                            Icons.cookie_outlined,
                            'Cookie & Tracking Policy',
                            null,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LegalDocumentPage(
                                  document: LegalDocuments.cookiePolicy,
                                ),
                              ),
                            ),
                          ),
                        ], palette),
                        SizedBox(height: 22),
                        _buildSection('Support', [
                          (
                            Icons.help_outline_rounded,
                            'Help Center',
                            null,
                            () => _showInfo(
                              context,
                              'Help Center is coming soon.',
                            ),
                          ),
                          (
                            Icons.info_outline_rounded,
                            'About App',
                            null,
                            () => _showInfo(
                              context,
                              'iMoScan helps verify devices, manage checkout, repairs, and invoices.',
                            ),
                          ),
                        ], palette),
                        SizedBox(height: 28),
                        _buildLogoutBtn(palette),
                        SizedBox(height: 28),
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

  /// Owner name as the primary line, brand name directly underneath.
  ///
  /// Both are read from the account record — nothing here is hard-coded — and
  /// the space the removed avatar and email used to take is collapsed rather
  /// than left as a gap.
  Widget _buildIdentity(
    ProfileController ctrl,
    ProfileThemePalette palette,
  ) {
    return Obx(() {
      final ownerName = ctrl.fullName.isNotEmpty ? ctrl.fullName : 'Owner';
      final brandName = ctrl.shopName;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              ownerName,
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          if (brandName.isNotEmpty) ...[
            SizedBox(height: 2),
            Text(
              brandName,
              style: TextStyle(
                color: palette.primaryColor,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildSectionLabel(String label, ProfileThemePalette palette) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: palette.textSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  /// Rows are `(category icon, label, optional trailing value, action)` so
  /// every entry carries one aligned 24pt outline icon, as specified.
  Widget _buildSection(
    String? title,
    List<(IconData, String, String?, VoidCallback)> items,
    ProfileThemePalette palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          _buildSectionLabel(title, palette),
          SizedBox(height: 10),
        ],
        ...items.map(
          (item) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ProfileMenuItem(
              leadingIcon: item.$1,
              label: item.$2,
              value: item.$3,
              onTap: item.$4,
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
