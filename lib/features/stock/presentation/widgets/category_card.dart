import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';

class CategoryCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final name = category['name']?.toString().trim().isNotEmpty == true ? category['name'].toString().trim() : 'Category';
    final itemCount = category['itemCount'] ?? category['totalItems'] ?? 0;
    final imageUrl = category['image'] is Map ? category['image']['url'] : null;

    final borderRadius = BorderRadius.circular(8);
    final cardColor = isDark ? const Color(0xFF0F151D) : const Color(0x80FFFFFF);
    final borderColor = isDark ? const Color(0xFF253246) : const Color(0xFFE4E7EC);
    final titleColor = isDark ? const Color(0xFFF4F7FB) : const Color(0xFF1A1C1E);
    final subtitleColor = isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085);
    final arrowBg = isDark ? const Color(0xFFF2F5FA) : const Color(0xFF1B1F26);
    final arrowFg = isDark ? const Color(0xFF161C24) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.22) : const Color(0xFF111827).withValues(alpha: 0.04),
                blurRadius: isDark ? 18 : 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), gradient: _imagePanelGradient(isDark)),
                      child: imageUrl is String && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, _, _) => _FallbackImage(isDark: isDark),
                            )
                          : _FallbackImage(isDark: isDark),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: 0),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$itemCount Items',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: arrowBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.1),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_outward_rounded, size: 18, color: arrowFg),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Gradient _imagePanelGradient(bool isDark) {
    if (isDark) {
      return const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF121923), Color(0xFF0F151D)]);
    }

    return const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF9FBFF), Color(0xFFF3F6FB)]);
  }
}

class _FallbackImage extends StatelessWidget {
  final bool isDark;

  const _FallbackImage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.category_outlined,
        size: isDark ? 96 : 92,
        color: isDark ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFB9C5D8),
      ),
    );
  }
}
