import 'package:flutter/material.dart';

import '../theme/checkout_tokens.dart';

/// Category tile used on the Shortcuts tab.
class CheckoutShortcutCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;

  /// Artwork for the tile (a category's uploaded image). When it is missing or
  /// fails to load the card falls back to [icon], so a category without a
  /// picture still reads as "no image" rather than showing nothing.
  final String? imageUrl;
  final Color? backgroundColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? subtitleColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const CheckoutShortcutCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.inventory_2_rounded,
    this.imageUrl,
    this.backgroundColor,
    this.iconBackgroundColor,
    this.iconColor,
    this.textColor,
    this.subtitleColor,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor ?? CheckoutTokens.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor ?? CheckoutTokens.border),
            boxShadow: boxShadow ?? CheckoutTokens.shadow(blur: 16, y: 9),
          ),
          // The artwork leads and the label sits under it, so the card reads
          // as the category itself. A small chip pinned to a corner left the
          // middle of the tile empty and made every card look alike.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CardMedia(
                  imageUrl: imageUrl,
                  icon: icon,
                  iconColor: iconColor,
                  iconBackgroundColor: iconBackgroundColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CheckoutTokens.text(
                        size: 15.5,
                        weight: FontWeight.w800,
                        color: textColor,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CheckoutTokens.text(
                        size: 12,
                        weight: FontWeight.w600,
                        color: subtitleColor ?? CheckoutTokens.softText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Media header of a [CheckoutShortcutCard]: the category artwork when there
/// is one, otherwise [icon] centred on a soft panel so a picture-less category
/// still shows what it is missing.
class _CardMedia extends StatelessWidget {
  final String? imageUrl;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;

  const _CardMedia({
    required this.imageUrl,
    required this.icon,
    this.iconColor,
    this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
      child: Container(
        width: double.infinity,
        // Neutral, never accent-tinted: category art is often a transparent
        // PNG and a coloured panel behind it reads as a stain.
        color: iconBackgroundColor ?? CheckoutTokens.surfaceMuted,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        child: url.isEmpty
            ? _fallback()
            : Image.network(
                url,
                // Contain, not cover: these are logos and product shots, and
                // cropping them to a square loses what identifies them.
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _fallback(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CheckoutTokens.softText,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _fallback() {
    return Icon(
      icon,
      size: 30,
      color: iconColor ?? CheckoutTokens.softText.withValues(alpha: 0.55),
    );
  }
}
