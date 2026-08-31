import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/profile/presentation/controller/profile_controller.dart';
import '../../features/profile/presentation/pages/profile_page_view.dart';
import '../utils/colors.dart';
import 'shop_logo.dart';

/// Header action that replaces the shop logo badge.
///
/// The client asked for the logo to come off every screen; it now lives inside
/// this menu instead.
class MoreMenuButton extends StatelessWidget {
  final double size;

  const MoreMenuButton({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return _PressableSurface(
      onTap: () => _openMenu(context),
      size: size,
      child: _DotsGlyph(color: AppColors.textPrimary),
    );
  }

  Future<void> _openMenu(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const _MoreMenuSheet(),
    );
  }
}

/// Squircle surface with a soft two-layer lift and a press dip.
class _PressableSurface extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  final Widget child;

  const _PressableSurface({
    required this.onTap,
    required this.size,
    required this.child,
  });

  @override
  State<_PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<_PressableSurface> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.34),
            color: _isPressed
                ? AppColors.fieldBackground
                : AppColors.cardBackground,
            border: Border.all(
              color: AppColors.fieldBorder.withValues(alpha: isDark ? 1 : 0.7),
            ),
            boxShadow: _isPressed
                ? null
                : [
                    // Tight contact shadow plus a wider ambient one - reads as
                    // a lifted key rather than a flat outlined box.
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.22 : 0.05,
                      ),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.28 : 0.07,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Three crisp dots; the rounded Material icon renders soft at this size.
class _DotsGlyph extends StatelessWidget {
  final Color color;

  const _DotsGlyph({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 4.2,
          height: 4.2,
          margin: EdgeInsets.only(right: index == 2 ? 0 : 3.4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.88),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _MoreMenuSheet extends StatelessWidget {
  const _MoreMenuSheet();

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fieldBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (profileCtrl == null)
              const _ShopIdentity(imageUrl: '', shopName: '', ownerName: '')
            else
              Obx(
                () => _ShopIdentity(
                  imageUrl: profileCtrl.imageUrl,
                  shopName: profileCtrl.shopName,
                  ownerName: profileCtrl.fullName,
                ),
              ),
            const SizedBox(height: 18),
            _MoreMenuRow(
              icon: Icons.person_rounded,
              label: 'Profile & settings',
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const ProfilePageView());
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// The shop logo, shown here instead of in every page header.
class _ShopIdentity extends StatelessWidget {
  final String imageUrl;
  final String shopName;
  final String ownerName;

  const _ShopIdentity({
    required this.imageUrl,
    required this.shopName,
    required this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShopLogo(
          imageUrl: imageUrl,
          width: 74,
          height: 62,
          borderRadius: BorderRadius.circular(16),
          background: Colors.white.withValues(alpha: 0.96),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shopName.isEmpty ? 'Your shop' : shopName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ownerName.isEmpty ? 'Shopkeeper' : ownerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreMenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
