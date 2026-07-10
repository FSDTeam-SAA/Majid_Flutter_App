import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/token_meneger.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/controller/auth_controller.dart';
import '../../../auth/presentation/pages/login_screen_view.dart';
import '../controller/profile_controller.dart';
import '../controller/profile_theme_controller.dart';
import '../widgets/profile_menu_item.dart';
import 'business_health_score_page.dart';
import 'edit_profile_page.dart';
import 'payment_history_page.dart';
import 'shopkeeper_id_card_page.dart';
import 'upgrade_plan_page.dart';
import '../../../customer/presentation/pages/customer_page.dart';
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
    if (state == AppLifecycleState.resumed &&
        _profileCtrl.profileData.isEmpty) {
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

                if (profileCtrl.profileData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          color: palette.textSecondary,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load profile',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: profileCtrl.fetchProfile,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: palette.primaryColor),
                            foregroundColor: palette.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text('Retry'),
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
                          (
                            'Customers',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CustomerPage()),
                            ),
                          ),
                          (
                            'Suppliers',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SupplierPage()),
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
    BuildContext context,
    ProfileThemeController themeCtrl,
    ProfileThemePalette palette,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showThemePicker(context, themeCtrl, palette),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
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
              mainAxisSize: MainAxisSize.min,
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
                    Icons.palette_outlined,
                    color: palette.primaryColor,
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Column(
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
                      'Change Theme',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 14),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: palette.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    palette.title,
                    style: TextStyle(
                      color: palette.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: palette.textSecondary,
                  size: 14,
                ),
              ],
            ),
          ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Obx(() {
          final activePalette = themeCtrl.palette;
          return SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 14),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(color: activePalette.surfaceBorderColor),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(
                        activePalette.surfaceColor.withValues(alpha: 0.97),
                        activePalette.backgroundColor,
                      ),
                      Color.alphaBlend(
                        activePalette.primaryColor.withValues(alpha: 0.08),
                        activePalette.backgroundColor,
                      ),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: activePalette.brightness == Brightness.dark
                            ? 0.32
                            : 0.12,
                      ),
                      blurRadius: 28,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(18, 14, 18, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 5,
                          decoration: BoxDecoration(
                            color: activePalette.textSecondary.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Choose profile theme',
                                  style: TextStyle(
                                    color: activePalette.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Switch the mood of your profile with a richer preview before you apply it.',
                                  style: TextStyle(
                                    color: activePalette.textSecondary,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(sheetContext),
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: activePalette.surfaceColor.withValues(
                                    alpha: 0.72,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: activePalette.surfaceBorderColor,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: activePalette.textPrimary,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18),
                      _buildThemePreviewHero(activePalette),
                      SizedBox(height: 18),
                      ...ProfileThemeOption.values.map(
                        (option) => Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _buildThemeOption(
                            sheetContext,
                            themeCtrl,
                            option,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildThemePreviewHero(ProfileThemePalette palette) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: palette.gradient,
        border: Border.all(
          color: palette.surfaceBorderColor.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: palette.backgroundColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: palette.onPrimaryColor.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              'Live preview',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.backgroundColor.withValues(alpha: 0.24),
                  border: Border.all(
                    color: palette.onPrimaryColor.withValues(alpha: 0.14),
                    width: 1.4,
                  ),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: palette.textPrimary,
                  size: 26,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview your vibe',
                      style: TextStyle(
                        color: palette.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      palette.subtitle,
                      style: TextStyle(
                        color: palette.textSecondary.withValues(alpha: 0.92),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPreviewMiniCard(
                  palette: palette,
                  label: 'Cards',
                  accentColor: palette.primaryColor,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildPreviewMiniCard(
                  palette: palette,
                  label: 'Contrast',
                  accentColor: palette.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewMiniCard({
    required ProfileThemePalette palette,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.backgroundColor.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: palette.onPrimaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Clean layers with balanced spacing',
            style: TextStyle(
              color: palette.textSecondary.withValues(alpha: 0.92),
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  IconData _themeOptionIcon(ProfileThemeOption option) => switch (option) {
    ProfileThemeOption.midnight => Icons.nights_stay_rounded,
    ProfileThemeOption.sunrise => Icons.wb_sunny_rounded,
  };

  String _themeOptionMood(ProfileThemeOption option) => switch (option) {
    ProfileThemeOption.midnight => 'Deep contrast for focused late-night work',
    ProfileThemeOption.sunrise => 'Soft brightness for a lighter daytime feel',
  };

  List<Color> _themeOptionSwatches(ProfileThemePalette palette) => [
    palette.primaryColor,
    palette.surfaceColor,
    palette.textSecondary,
  ];

  Widget _buildOptionSwatch(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }

  Widget _buildOptionPreviewChip(
    ProfileThemePalette palette,
    String label,
    Color tone,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tone.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: palette.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await themeCtrl.setTheme(option);
          if (context.mounted) {
            Navigator.pop(context);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 220),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? optionPalette.primaryColor
                  : optionPalette.surfaceBorderColor,
              width: isSelected ? 1.8 : 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  optionPalette.surfaceColor.withValues(alpha: 0.98),
                  optionPalette.backgroundColor,
                ),
                Color.alphaBlend(
                  optionPalette.primaryColor.withValues(alpha: 0.12),
                  optionPalette.backgroundColor,
                ),
              ],
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: optionPalette.primaryColor.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: optionPalette.gradient,
                      border: Border.all(
                        color: optionPalette.surfaceBorderColor.withValues(
                          alpha: 0.9,
                        ),
                      ),
                    ),
                    child: Icon(
                      _themeOptionIcon(option),
                      color: optionPalette.primaryColor,
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                optionPalette.title,
                                style: TextStyle(
                                  color: optionPalette.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            if (isSelected)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: optionPalette.primaryColor.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    color: optionPalette.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          _themeOptionMood(option),
                          style: TextStyle(
                            color: optionPalette.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? optionPalette.primaryColor
                          : optionPalette.surfaceColor.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? optionPalette.primaryColor
                            : optionPalette.surfaceBorderColor,
                      ),
                    ),
                    child: Icon(
                      isSelected
                          ? Icons.check_rounded
                          : Icons.arrow_forward_ios_rounded,
                      color: isSelected
                          ? optionPalette.onPrimaryColor
                          : optionPalette.textSecondary,
                      size: isSelected ? 18 : 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  ..._themeOptionSwatches(optionPalette).map(
                    (color) => Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: _buildOptionSwatch(color),
                    ),
                  ),
                  Spacer(),
                  _buildOptionPreviewChip(
                    optionPalette,
                    optionPalette.subtitle,
                    optionPalette.primaryColor,
                  ),
                ],
              ),
            ],
          ),
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
