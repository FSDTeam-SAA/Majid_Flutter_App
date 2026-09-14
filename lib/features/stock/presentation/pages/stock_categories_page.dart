import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/more_menu_button.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';
import '../../domain/entities/category.dart';
import '../controller/stock_basket_controller.dart';
import '../controller/stock_controller.dart';
import '../theme/checkout_tokens.dart';
import '../widgets/checkout_icon_button.dart';
import '../widgets/checkout_search_field.dart';
import 'add_category_sheet.dart';
import 'add_new_device_page.dart';
import 'category_stock_page.dart';
import 'stock_checkout_review_page.dart';

/// Entry point of the Stock section: displays categories same as website,
/// with image previews, item counts, edit/delete actions, and quick category/device creation.
class StockCategoriesPage extends StatefulWidget {
  const StockCategoriesPage({super.key});

  @override
  State<StockCategoriesPage> createState() => _StockCategoriesPageState();
}

class _StockCategoriesPageState extends State<StockCategoriesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final StockController _stockCtrl;
  late final StockBasketController _basket;

  @override
  void initState() {
    super.initState();
    _stockCtrl = Get.find<StockController>();
    _basket = StockBasketController.instance;
    if (_stockCtrl.categories.isEmpty) _stockCtrl.fetchCategories();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _query => _searchCtrl.text.trim().toLowerCase();

  List<Category> get _visibleCategories {
    final categories = _stockCtrl.inventoryCategoryCards.isNotEmpty
        ? _stockCtrl.inventoryCategoryCards.toList()
        : _stockCtrl.categories.toList();
    if (_query.isEmpty) return categories;
    return categories
        .where((category) => category.name.toLowerCase().contains(_query))
        .toList();
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryStockPage(initialSearch: code.trim()),
      ),
    );
  }

  void _openReview() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StockCheckoutReviewPage()),
    );
  }

  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Category',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await _stockCtrl.deleteCategory(category.id);
              if (success) {
                showSuccessSnackbar('Category deleted successfully');
              } else {
                showErrorSnackbar(
                  _stockCtrl.errorMessage.value.isNotEmpty
                      ? _stockCtrl.errorMessage.value
                      : 'Failed to delete category',
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFFF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Get.find<ProfileController>().currencySymbol;

    return GradientScaffold(
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Row(
              children: [
                if (Navigator.canPop(context))
                  CheckoutIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  )
                else
                  const MoreMenuButton(size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() {
                    final count = _visibleCategories.length;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stock Categories',
                          style: CheckoutTokens.text(
                            size: 20,
                            weight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          '$count ${count == 1 ? 'category' : 'categories'} available',
                          style: CheckoutTokens.text(
                            size: 12,
                            weight: FontWeight.w600,
                            color: CheckoutTokens.softText,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),

          // Action Buttons Bar (same as website: Add Item, Add Category)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddNewDevicePage()),
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: CheckoutTokens.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CheckoutTokens.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Add Device',
                              style: CheckoutTokens.text(
                                size: 13,
                                weight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => showAddCategorySheet(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: CheckoutTokens.accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: CheckoutTokens.accent.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Add Category',
                              style: CheckoutTokens.text(
                                size: 13,
                                weight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: CheckoutSearchField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              onClear: () => setState(_searchCtrl.clear),
              onScan: _scan,
            ),
          ),

          // Categories Grid / Empty Panel
          Expanded(
            child: Obx(() {
              _stockCtrl.isLoading.value;
              final categories = _visibleCategories;

              return RefreshIndicator(
                color: CheckoutTokens.accent,
                backgroundColor: CheckoutTokens.surface,
                onRefresh: _stockCtrl.fetchCategories,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  children: [
                    if (categories.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 48,
                          horizontal: 24,
                        ),
                        decoration: BoxDecoration(
                          color: CheckoutTokens.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: CheckoutTokens.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CheckoutTokens.accentSoft,
                              ),
                              child: Icon(
                                Icons.folder_open_rounded,
                                size: 32,
                                color: CheckoutTokens.accent,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No categories found',
                              style: CheckoutTokens.text(
                                size: 17,
                                weight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create a category to organize inventory items.',
                              textAlign: TextAlign.center,
                              style: CheckoutTokens.text(
                                size: 13,
                                color: CheckoutTokens.softText,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => showAddCategorySheet(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text(
                                'Add Category',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CheckoutTokens.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: categories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.86,
                            ),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _WebsiteCategoryCard(
                            category: category,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryStockPage(
                                  categoryId: category.id,
                                  categoryName: category.name,
                                ),
                              ),
                            ),
                            onEdit: () => showAddCategorySheet(
                              context,
                              existingId: category.id,
                              existingName: category.name,
                              existingImageUrl: category.imageUrl,
                            ),
                            onDelete: () => _confirmDeleteCategory(category),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    _AllStockRow(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoryStockPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          // Review Bar (when basket items exist)
          Obx(() {
            if (_basket.lines.isEmpty) return const SizedBox.shrink();
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _ReviewBar(
                  label:
                      '${_basket.totalQuantity} item${_basket.totalQuantity == 1 ? '' : 's'} ready',
                  amount: '$currency${_basket.total.toStringAsFixed(2)}',
                  onTap: _openReview,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Category card styled identically to the website (`Inventory.tsx` category cards):
/// Displays category image with fallback folder icon, top-right 3-dots popup menu
/// with Edit/Delete options, bold category name, item count, and package icon badge.
class _WebsiteCategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WebsiteCategoryCard({
    required this.category,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        category.imageUrl != null && category.imageUrl!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: CheckoutTokens.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CheckoutTokens.border),
            boxShadow: CheckoutTokens.shadow(blur: 14, y: 6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top visual preview (Photo or Folder icon) + 3-dots menu
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: AppColors.isDark
                            ? const Color(0xFF0D141F)
                            : const Color(0xFFF1F5F9),
                        child: hasImage
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.network(
                                  category.imageUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      _buildFolderPlaceholder(),
                                ),
                              )
                            : _buildFolderPlaceholder(),
                      ),
                    ),
                    // Top-right 3-dots menu (Edit & Delete)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: (AppColors.isDark
                                    ? Colors.black
                                    : Colors.white)
                                .withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: CheckoutTokens.border),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            height: 38,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Edit Category',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            height: 38,
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFFF4444),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Info Area (Name, Subtitle, Package badge)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CheckoutTokens.text(
                              size: 14.5,
                              weight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            category.itemCount > 0
                                ? '${category.itemCount} item${category.itemCount == 1 ? '' : 's'}'
                                : 'Open inventory',
                            style: CheckoutTokens.text(
                              size: 11.5,
                              weight: FontWeight.w600,
                              color: CheckoutTokens.softText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CheckoutTokens.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: CheckoutTokens.accent,
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

  Widget _buildFolderPlaceholder() {
    return Center(
      child: Icon(
        Icons.folder_open_rounded,
        size: 44,
        color: CheckoutTokens.accent.withValues(alpha: 0.45),
      ),
    );
  }
}

class _AllStockRow extends StatelessWidget {
  final VoidCallback onTap;

  const _AllStockRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: CheckoutTokens.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CheckoutTokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: CheckoutTokens.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 18,
                  color: CheckoutTokens.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Browse all stock',
                  style: CheckoutTokens.text(size: 14, weight: FontWeight.w700),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: CheckoutTokens.softText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewBar extends StatelessWidget {
  final String label;
  final String amount;
  final VoidCallback onTap;

  const _ReviewBar({
    required this.label,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          decoration: BoxDecoration(
            gradient: CheckoutTokens.limeGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: CheckoutTokens.text(
                    size: 14,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                amount,
                style: CheckoutTokens.text(
                  size: 15,
                  weight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
