import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../utils/shop_logo_settings.dart';

/// Draws the shop logo with the zoom, nudge and fit chosen in
/// Settings → Invoice & Logo, so every surface matches that preview.
class ShopLogo extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? background;
  final double fallbackIconSize;

  const ShopLogo({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.borderRadius,
    this.background,
    this.fallbackIconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(14);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: width,
        height: height,
        color: background ?? AppColors.primary.withValues(alpha: 0.12),
        child: imageUrl.isEmpty
            ? _fallback()
            : ValueListenableBuilder<ShopLogoSettings>(
                valueListenable: ShopLogoSettings.current,
                builder: (context, settings, _) {
                  return Transform.translate(
                    offset: Offset(
                      settings.nudgeX(width),
                      settings.nudgeY(height),
                    ),
                    child: Transform.scale(
                      scale: settings.zoom,
                      child: Image.network(
                        imageUrl,
                        fit: settings.fillContainer
                            ? BoxFit.cover
                            : BoxFit.contain,
                        alignment: Alignment(
                          settings.offsetX,
                          settings.offsetY,
                        ),
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, _, _) => _fallback(),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        Icons.storefront_rounded,
        color: AppColors.textSecondary,
        size: fallbackIconSize,
      ),
    );
  }
}
