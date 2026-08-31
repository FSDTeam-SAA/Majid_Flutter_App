import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/shop_logo_settings.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../controller/profile_controller.dart';

class InvoiceLogoSettingsPage extends StatefulWidget {
  const InvoiceLogoSettingsPage({super.key});

  @override
  State<InvoiceLogoSettingsPage> createState() =>
      _InvoiceLogoSettingsPageState();
}

class _InvoiceLogoSettingsPageState extends State<InvoiceLogoSettingsPage> {
  static const _bgModeKey = 'invoice_logo_bg_mode';

  late final ProfileController _profileCtrl;

  String? _pickedImagePath;
  _LogoFitMode _fitMode = _LogoFitMode.contain;
  _PreviewBackgroundMode _backgroundMode = _PreviewBackgroundMode.transparent;
  double _zoom = 1;
  double _offsetX = 0;
  double _offsetY = 0;
  bool _isPrefsReady = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileCtrl = Get.find<ProfileController>();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    final shared = await ShopLogoSettings.load();
    final prefs = await SharedPreferences.getInstance();
    final bgModeName = prefs.getString(_bgModeKey);

    if (!mounted) return;
    setState(() {
      _fitMode = shared.fillContainer
          ? _LogoFitMode.cover
          : _LogoFitMode.contain;
      _backgroundMode = _PreviewBackgroundMode.values.firstWhere(
        (mode) => mode.name == bgModeName,
        orElse: () => _PreviewBackgroundMode.transparent,
      );
      _zoom = shared.zoom;
      _offsetX = shared.offsetX;
      _offsetY = shared.offsetY;
      _isPrefsReady = true;
    });
  }

  Future<void> _pickLogoImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null || !mounted) return;

    setState(() => _pickedImagePath = picked.path);
  }

  Future<void> _saveSettings() async {
    final profile = _profileCtrl.profile.value;
    if (profile == null) {
      showErrorSnackbar('Profile is not ready yet. Please try again.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_pickedImagePath != null && _pickedImagePath!.isNotEmpty) {
        final success = await _profileCtrl.updateProfile(
          firstName: profile.firstName,
          lastName: profile.lastName,
          phone: profile.phone,
          whatsappNumber: profile.whatsappNumber,
          shopName: profile.shopName,
          shopAddress: profile.shopAddress,
          imagePath: _pickedImagePath,
        );
        if (!success) {
          showErrorSnackbar(
            _profileCtrl.errorMessage.value.isNotEmpty
                ? _profileCtrl.errorMessage.value
                : 'Failed to update logo',
          );
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bgModeKey, _backgroundMode.name);
      // Written through the shared store so invoices and the More menu pick
      // the change up straight away.
      await ShopLogoSettings.save(
        ShopLogoSettings(
          zoom: _zoom,
          offsetX: _offsetX,
          offsetY: _offsetY,
          fillContainer: _fitMode == _LogoFitMode.cover,
        ),
      );

      await _profileCtrl.fetchProfile();
      if (!mounted) return;

      setState(() => _pickedImagePath = null);
      showSuccessSnackbar('Logo settings saved successfully');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _resetControls() async {
    await ShopLogoSettings.save(const ShopLogoSettings());
    if (!mounted) return;
    setState(() {
      _fitMode = _LogoFitMode.contain;
      _backgroundMode = _PreviewBackgroundMode.transparent;
      _zoom = 1;
      _offsetX = 0;
      _offsetY = 0;
      _pickedImagePath = null;
    });
  }

  ImageProvider? _logoProvider() {
    if (_pickedImagePath != null && _pickedImagePath!.isNotEmpty) {
      return FileImage(File(_pickedImagePath!));
    }

    final url = _profileCtrl.imageUrl;
    if (url.isNotEmpty) {
      return NetworkImage(url);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Invoice & Logo', trailing: _buildSaveButton()),
          Expanded(
            child: !_isPrefsReady
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogoSourceCard(),
                        const SizedBox(height: 16),
                        _buildQuickFitCard(),
                        const SizedBox(height: 16),
                        _buildPreviewCard(),
                        const SizedBox(height: 16),
                        _buildZoomCard(),
                        const SizedBox(height: 16),
                        _buildPanCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: 92,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.buttonText,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSaving
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.buttonText,
                ),
              )
            : const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildLogoSourceCard() {
    final provider = _logoProvider();

    return _buildSectionCard(
      title: 'Shop Logo Source',
      subtitle: 'Use your current profile image or upload a cleaner logo file.',
      trailing: TextButton(
        onPressed: _resetControls,
        child: Text(
          'Reset',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 92,
              height: 92,
              color: AppColors.fieldBackground,
              child: provider == null
                  ? Icon(
                      Icons.storefront_rounded,
                      color: AppColors.textSecondary,
                      size: 34,
                    )
                  : Image(
                      image: provider,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.storefront_rounded,
                        color: AppColors.textSecondary,
                        size: 34,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pickedImagePath != null
                      ? 'New logo ready to save'
                      : (_profileCtrl.imageUrl.isNotEmpty
                            ? 'Saved logo loaded'
                            : 'No saved logo found'),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'PNG, SVG-style artwork image, or JPG with a clean background works best.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        label: _pickedImagePath != null
                            ? 'Change Logo'
                            : 'Upload Logo',
                        icon: Icons.upload_rounded,
                        onTap: _pickLogoImage,
                        isPrimary: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        label: 'Use Current',
                        icon: Icons.refresh_rounded,
                        onTap: () => setState(() => _pickedImagePath = null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFitCard() {
    return _buildSectionCard(
      title: 'Quick Fit Modes',
      subtitle:
          'Decide whether the full logo stays visible or fills the frame.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildChoiceTile(
                  title: 'Fit Entire Logo',
                  subtitle: 'Keeps every edge visible',
                  selected: _fitMode == _LogoFitMode.contain,
                  onTap: () => setState(() => _fitMode = _LogoFitMode.contain),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceTile(
                  title: 'Fill Container',
                  subtitle: 'Fills the box more tightly',
                  selected: _fitMode == _LogoFitMode.cover,
                  onTap: () => setState(() => _fitMode = _LogoFitMode.cover),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildChoiceTile(
                  title: 'Transparent BG',
                  subtitle: 'Uses app theme behind preview',
                  selected:
                      _backgroundMode == _PreviewBackgroundMode.transparent,
                  onTap: () => setState(
                    () => _backgroundMode = _PreviewBackgroundMode.transparent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildChoiceTile(
                  title: 'White BG',
                  subtitle: 'Shows paper-style contrast',
                  selected: _backgroundMode == _PreviewBackgroundMode.white,
                  onTap: () => setState(
                    () => _backgroundMode = _PreviewBackgroundMode.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return _buildSectionCard(
      title: 'Interactive Preview',
      subtitle:
          'Preview how the logo feels on an invoice header before saving.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildPreviewPill('Invoice PDF'),
                const SizedBox(width: 8),
                _buildPreviewPill('Receipt'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _backgroundMode == _PreviewBackgroundMode.white
                    ? Colors.white
                    : AppColors.cardBackground.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _backgroundMode == _PreviewBackgroundMode.white
                      ? const Color(0xFFE6EAF0)
                      : AppColors.fieldBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreviewLogoBox(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profileCtrl.shopName.isNotEmpty
                                  ? _profileCtrl.shopName
                                  : 'Your Shop Name',
                              style: TextStyle(
                                color:
                                    _backgroundMode ==
                                        _PreviewBackgroundMode.white
                                    ? const Color(0xFF101828)
                                    : AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profileCtrl.shopAddress.isNotEmpty
                                  ? _profileCtrl.shopAddress
                                  : '123 Market Street',
                              style: TextStyle(
                                color:
                                    _backgroundMode ==
                                        _PreviewBackgroundMode.white
                                    ? const Color(0xFF667085)
                                    : AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'INVOICE',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '#INV-2026-001',
                            style: TextStyle(
                              color:
                                  _backgroundMode ==
                                      _PreviewBackgroundMode.white
                                  ? const Color(0xFF667085)
                                  : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildPreviewLine(widthFactor: 1),
                  const SizedBox(height: 8),
                  _buildPreviewLine(widthFactor: 0.78),
                  const SizedBox(height: 8),
                  _buildPreviewLine(widthFactor: 0.64),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewLogoBox() {
    final provider = _logoProvider();
    final previewBg = _backgroundMode == _PreviewBackgroundMode.white
        ? const Color(0xFFF8FAFC)
        : AppColors.fieldBackground;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 110,
        height: 72,
        color: previewBg,
        child: provider == null
            ? Center(
                child: Icon(
                  Icons.storefront_rounded,
                  color: AppColors.textSecondary,
                  size: 30,
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Transform.translate(
                    offset: Offset(_offsetX * 18, _offsetY * 12),
                    child: Transform.scale(
                      scale: _zoom,
                      child: Image(
                        image: provider,
                        fit: _fitMode == _LogoFitMode.contain
                            ? BoxFit.contain
                            : BoxFit.cover,
                        alignment: Alignment(_offsetX, _offsetY),
                        errorBuilder: (_, _, _) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.textSecondary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPreviewLine({required double widthFactor}) {
    final lineColor = _backgroundMode == _PreviewBackgroundMode.white
        ? const Color(0xFFD0D5DD)
        : AppColors.fieldBorder;

    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 7,
        decoration: BoxDecoration(
          color: lineColor,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildPreviewPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildZoomCard() {
    return _buildSectionCard(
      title: 'Scale / Zoom Level',
      subtitle: 'Make the mark more compact or more dominant inside the frame.',
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.zoom_in_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.fieldBorder,
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.12),
                    trackHeight: 4.5,
                  ),
                  child: Slider(
                    min: 0.8,
                    max: 2.4,
                    value: _zoom,
                    onChanged: (value) => setState(() => _zoom = value),
                  ),
                ),
              ),
              Container(
                width: 58,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Text(
                  '${(_zoom * 100).round()}%',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '80% (Compact)',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              Text(
                '240% (Large)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanCard() {
    return _buildSectionCard(
      title: 'Manual Panning / Alignment',
      subtitle:
          'Shift the preview a little if the logo feels too centered or clipped.',
      child: Column(
        children: [
          _buildAxisSlider(
            label: 'Horizontal (X)',
            value: _offsetX,
            onChanged: (value) => setState(() => _offsetX = value),
          ),
          const SizedBox(height: 14),
          _buildAxisSlider(
            label: 'Vertical (Y)',
            value: _offsetY,
            onChanged: (value) => setState(() => _offsetY = value),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Center Again',
                  icon: Icons.center_focus_strong_rounded,
                  onTap: () => setState(() {
                    _offsetX = 0;
                    _offsetY = 0;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  label: 'Reset All',
                  icon: Icons.restart_alt_rounded,
                  onTap: _resetControls,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAxisSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.fieldBorder,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
            trackHeight: 4.5,
          ),
          child: Slider(min: -1, max: 1, value: value, onChanged: onChanged),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing],
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildChoiceTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.fieldBackground.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.fieldBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: isPrimary
              ? AppColors.primary.withValues(alpha: AppColors.isDark ? 0.2 : 1)
              : AppColors.fieldBackground.withValues(alpha: 0.76),
          foregroundColor: isPrimary
              ? AppColors.primary
              : AppColors.textPrimary,
          side: BorderSide(
            color: isPrimary ? AppColors.primary : AppColors.fieldBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

enum _LogoFitMode { contain, cover }

enum _PreviewBackgroundMode { transparent, white }
