import 'package:flutter/material.dart';

import '../../../../../core/utils/colors.dart';

class CategoryEntity {
  final String name;
  final int itemCount;
  final IconData icon;
  final Color bgColor;

  const CategoryEntity({
    required this.name,
    required this.itemCount,
    required this.icon,
    required this.bgColor,
  });
}

class CategoryCard extends StatelessWidget {
  final CategoryEntity category;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // background
            Container(
              color: category.bgColor,
              child: Icon(category.icon, size: 90, color: Colors.white10),
            ),

            // bottom gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.35, 1.0],
                  colors: [Colors.transparent, Color(0xEE0B0F14)],
                ),
              ),
            ),

            // content at bottom
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              category.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${category.itemCount} Items',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_outward,
                          size: 16,
                          color: AppColors.background,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
