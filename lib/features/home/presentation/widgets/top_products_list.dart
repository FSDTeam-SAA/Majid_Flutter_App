import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

class TopProductsList extends StatelessWidget {
  final List<(String, int)> products;

  const TopProductsList({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Top Selling Products',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              'View All',
              style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(products.length, (i) {
          final (name, sold) = products[i];
          final progress = sold / products[0].$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.fieldBackground, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.phone_iphone, color: AppColors.textSecondary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.fieldBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$sold',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const Text('Sold', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
