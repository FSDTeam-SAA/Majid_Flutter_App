import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../controller/stock_basket_controller.dart';
import '../theme/checkout_tokens.dart';
import '../widgets/checkout_empty_panel.dart';
import '../widgets/checkout_icon_button.dart';
import '../widgets/checkout_search_field.dart';
import 'stock_checkout_review_page.dart';

/// Stock inside one category (or the whole catalogue when no category is
/// given), with the per-item quantity stepper and Sell action.
class CategoryStockPage extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;

  /// Pre-fills the search box — used when the shopkeeper scanned a barcode,
  /// IMEI or serial from the categories screen.
  final String? initialSearch;

  const CategoryStockPage({
    super.key,
    this.categoryId,
    this.categoryName,
    this.initialSearch,
  });

  @override
  State<CategoryStockPage> createState() => _CategoryStockPageState();
}

class _CategoryStockPageState extends State<CategoryStockPage> {
  late final InventoryRepository _repo;
  late final ProfileController _profileCtrl;
  late final StockBasketController _basket;
  final TextEditingController _searchCtrl = TextEditingController();

  /// Quantity picked per item before it is sent to Checkout Review.
  final Map<String, int> _pending = {};

  List<InventoryItem> _items = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _repo = InventoryRepositoryImpl(ApiClient(baseUrl));
    _profileCtrl = Get.find<ProfileController>();
    _basket = StockBasketController.instance;
    if (widget.initialSearch != null) {
      _searchCtrl.text = widget.initialSearch!;
    }
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      var id = _profileCtrl.userId;
      if (id.isEmpty) {
        await _profileCtrl.fetchProfile();
        id = _profileCtrl.userId;
      }
      final items = id.isEmpty
          ? await _repo.getMyInventory()
          : await _repo.getByShopkeeperId(id);
      if (!mounted) return;
      setState(() => _items = items);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(
        () => _error =
            e.response?.data?['message']?.toString() ?? 'Failed to load stock',
      );
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load stock');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _query => _searchCtrl.text.trim().toLowerCase();

  List<InventoryItem> get _visibleItems {
    var items = _items;

    final categoryId = widget.categoryId;
    final categoryName = widget.categoryName?.trim().toLowerCase();
    if (categoryId != null && categoryId.isNotEmpty) {
      items = items
          .where(
            (item) =>
                item.categoryId == categoryId ||
                (categoryName != null &&
                    (item.categoryName ?? '').trim().toLowerCase() ==
                        categoryName),
          )
          .toList();
    }

    final query = _query;
    if (query.isEmpty) return items;

    return items.where((item) {
      final haystack = [
        item.itemName,
        item.brand,
        item.imeiNumber,
        item.sku,
        item.modelNumber,
        item.storage,
        item.color,
        item.categoryName,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  int _quantityFor(InventoryItem item) => _pending[item.id] ?? 1;

  void _step(InventoryItem item, int delta) {
    final next = (_quantityFor(item) + delta).clamp(1, 999);
    setState(() => _pending[item.id] = next);
  }

  /// Queues the item for Checkout Review. Stock is not decremented here —
  /// that happens only once payment completes.
  void _sell(InventoryItem item) {
    _basket.add(item, quantity: _quantityFor(item));
    setState(() => _pending.remove(item.id));
    showSuccessSnackbar('${item.itemName} added to checkout');
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;
    setState(() => _searchCtrl.text = code.trim());
  }

  @override
  Widget build(BuildContext context) {
    final currency = _profileCtrl.currencySymbol;
    final title = widget.categoryName?.isNotEmpty == true
        ? '${widget.categoryName} Stock'
        : 'All Stock';

    return GradientScaffold(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
            child: Row(
              children: [
                CheckoutIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: CheckoutTokens.text(
                      size: 20,
                      weight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
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
          Expanded(child: _buildBody(currency)),
          Obx(() {
            if (_basket.lines.isEmpty) return const SizedBox.shrink();
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: _GoToReviewButton(
                  label:
                      'Checkout Review · ${_basket.totalQuantity} item${_basket.totalQuantity == 1 ? '' : 's'}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StockCheckoutReviewPage(),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBody(String currency) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: CheckoutTokens.accent),
      );
    }

    if (_error.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: CheckoutEmptyPanel(
          icon: Icons.wifi_tethering_error_rounded,
          title: 'Could not load stock',
          subtitle: _error,
        ),
      );
    }

    final items = _visibleItems;
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: CheckoutEmptyPanel(
          icon: Icons.search_off_rounded,
          title: 'Nothing in stock here',
          subtitle: 'Try another category, search or scan an item.',
        ),
      );
    }

    return RefreshIndicator(
      color: CheckoutTokens.accent,
      backgroundColor: CheckoutTokens.surface,
      onRefresh: _fetch,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _StockRow(
            item: item,
            currencySymbol: currency,
            quantity: _quantityFor(item),
            onDecrement: () => _step(item, -1),
            onIncrement: () => _step(item, 1),
            onSell: () => _sell(item),
          );
        },
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final InventoryItem item;
  final String currencySymbol;
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onSell;

  const _StockRow({
    required this.item,
    required this.currencySymbol,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final stockLabel = item.quantity > 0
        ? '${item.quantity} in stock'
        : 'Stock not tracked';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CheckoutTokens.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CheckoutTokens.border),
        boxShadow: CheckoutTokens.shadow(blur: 14, y: 8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 58,
              height: 58,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CheckoutTokens.text(
                    size: 14.5,
                    weight: FontWeight.w800,
                  ),
                ),
                if ((item.color ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.color!,
                    style: CheckoutTokens.text(
                      size: 12,
                      weight: FontWeight.w600,
                      color: CheckoutTokens.softText,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  stockLabel,
                  style: CheckoutTokens.text(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: CheckoutTokens.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$currencySymbol${item.price.toStringAsFixed(item.price % 1 == 0 ? 0 : 2)}',
                  style: CheckoutTokens.text(
                    size: 16,
                    weight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StepButton(icon: Icons.remove_rounded, onTap: onDecrement),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: CheckoutTokens.text(
                          size: 14,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StepButton(icon: Icons.add_rounded, onTap: onIncrement),
                    const Spacer(),
                    _SellButton(onTap: onSell),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: CheckoutTokens.surfaceMuted,
      child: Icon(
        Icons.phone_iphone_rounded,
        color: CheckoutTokens.softText,
        size: 26,
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: CheckoutTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: CheckoutTokens.border),
          ),
          child: Icon(icon, size: 17, color: CheckoutTokens.strongText),
        ),
      ),
    );
  }
}

class _SellButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SellButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
          decoration: BoxDecoration(
            gradient: CheckoutTokens.limeGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Sell',
            style: CheckoutTokens.text(
              size: 13,
              weight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoToReviewButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GoToReviewButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: CheckoutTokens.ctaBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: CheckoutTokens.text(
                size: 14.5,
                weight: FontWeight.w800,
                color: CheckoutTokens.ctaForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
