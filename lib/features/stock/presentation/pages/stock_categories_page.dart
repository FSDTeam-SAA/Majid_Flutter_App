import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';
import '../../domain/entities/category.dart';
import '../controller/stock_controller.dart';
import '../theme/checkout_tokens.dart';
import '../widgets/checkout_empty_panel.dart';
import '../widgets/checkout_icon_button.dart';
import '../widgets/checkout_search_field.dart';
import '../widgets/checkout_shortcut_card.dart';
import 'category_stock_page.dart';

/// Entry point of the Stock section: "Choose a category or scan an item".
///
/// Reached from Quick Stock Access on the checkout header. Browsing by
/// category and searching (including by IMEI/serial, via the scanner in the
/// search field) both land on the same [CategoryStockPage].
class StockCategoriesPage extends StatefulWidget {
  const StockCategoriesPage({super.key});

  @override
  State<StockCategoriesPage> createState() => _StockCategoriesPageState();
}

class _StockCategoriesPageState extends State<StockCategoriesPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  late final StockController _stockCtrl;

  @override
  void initState() {
    super.initState();
    _stockCtrl = Get.find<StockController>();
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

  /// A scanned barcode/IMEI is a stock lookup, not a category filter, so it
  /// opens the all-stock list pre-filtered on the scanned code.
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

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Row(
              children: [
                // This screen is both the first bottom-nav destination and
                // a page pushed from Quick Stock Access. As a tab there is
                // nothing to go back to, so the header simply starts with the
                // title.
                if (Navigator.canPop(context)) ...[
                  CheckoutIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
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
                        'Choose a category or scan an item',
                        style: CheckoutTokens.text(
                          size: 12,
                          weight: FontWeight.w600,
                          color: CheckoutTokens.softText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
            child: CheckoutSearchField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              onClear: () => setState(_searchCtrl.clear),
              onScan: _scan,
            ),
          ),
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
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  children: [
                    if (categories.isEmpty)
                      const CheckoutEmptyPanel(
                        icon: Icons.category_outlined,
                        title: 'No stock categories yet',
                        subtitle:
                            'Add a category or device and it will show up here.',
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
                              childAspectRatio: 0.92,
                            ),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return CheckoutShortcutCard(
                            title: category.name,
                            subtitle: 'View stock',
                            imageUrl: category.imageUrl,
                            // No artwork yet -> a picture icon, so the tile
                            // says "this category has no image" instead of
                            // looking identical to every other card.
                            icon: Icons.image_outlined,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CategoryStockPage(
                                  categoryId: category.id,
                                  categoryName: category.name,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            }),
          ),
          // Pinned above the bottom nav instead of riding at the end of the
          // grid: browsing all stock is the page's standing escape hatch, so
          // it should be reachable without scrolling past every category.
          Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              6,
              18,
              10 + MediaQuery.paddingOf(context).bottom * 0.2,
            ),
            child: _AllStockRow(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryStockPage()),
              ),
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: CheckoutTokens.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CheckoutTokens.border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: CheckoutTokens.accentSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 17,
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
