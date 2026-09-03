import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart'
    show RepairRequestEndpoints, baseUrl;
import '../../../../core/theme/app_theme_controller.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../auth/presentation/controller/auth_controller.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../supplier/presentation/pages/supplier_page.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/ready_order.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';
import '../controller/stock_controller.dart';
import '../theme/checkout_tokens.dart';
import '../utils/amount_expression.dart';
import '../widgets/checkout_amount_card.dart';
import '../widgets/checkout_empty_panel.dart';
import '../widgets/checkout_icon_button.dart';
import '../widgets/checkout_keypad.dart';
import '../widgets/checkout_product_row.dart';
import '../widgets/checkout_search_field.dart';
import '../widgets/checkout_section_header.dart';
import '../widgets/checkout_shortcut_card.dart';
import '../widgets/checkout_tab_bar.dart';
import '../widgets/checkout_total_qty_button.dart';
import '../widgets/price_edit_sheet.dart';
import '../widgets/price_override_summary.dart';
import '../widgets/ready_orders_card.dart';
import '../widgets/ready_orders_sheet.dart';
import '../../domain/entities/calculation_line.dart';
import 'calculation_note_page.dart';
import 'quantity_review_page.dart';
import 'add_category_sheet.dart';
import 'add_new_device_page.dart';
import 'inventory_screen.dart';
import 'manage_categories_page.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  static const _listPadding = EdgeInsets.fromLTRB(18, 18, 18, 24);

  late final ApiClient _api;
  late final InventoryRepository _inventoryRepo;
  late final CartRepository _cartRepo;
  late final StockController _stockCtrl;
  late final ProfileController _profileCtrl;
  late final AuthController _authCtrl;

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();

  /// Checkout-time price overrides, keyed by inventory item id.
  final Map<String, double> _priceOverrides = {};

  CheckoutTab _selectedTab = CheckoutTab.keypad;
  bool _isSearchOpen = false;
  bool _isReadyOrdersSheetOpen = false;
  List<InventoryItem> _inventoryItems = [];
  List<ReadyOrder> _readyOrders = [];
  bool _isInventoryLoading = true;
  String _inventoryError = '';
  AmountExpression _expression = AmountExpression.empty;

  /// Names given to calculated lines, keyed by the term as typed.
  final Map<String, String> _lineNames = {};
  String _calculationNote = '';

  @override
  void initState() {
    super.initState();
    final api = ApiClient(baseUrl);
    _api = api;
    _inventoryRepo = InventoryRepositoryImpl(api);
    _cartRepo = CartRepositoryImpl(api);
    _stockCtrl = Get.find<StockController>();
    _profileCtrl = Get.find<ProfileController>();
    _authCtrl = Get.find<AuthController>();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _stockCtrl.fetchCategories(),
      _fetchInventory(),
      _fetchReadyOrders(),
    ]);
  }

  /// Repairs the technicians have finished, ready to be collected and paid
  /// for. Failures fall back to an empty state in the sheet.
  Future<void> _fetchReadyOrders() async {
    try {
      final res = await _api.get(
        RepairRequestEndpoints.completed,
        query: {'page': 1, 'limit': 20},
      );
      final data = res.data['data'];
      if (data is! List || !mounted) return;

      setState(() {
        _readyOrders = data
            .whereType<Map>()
            .map((item) => ReadyOrder.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => _readyOrders = []);
    }
  }

  Future<void> _openReadyOrders() async {
    if (_isReadyOrdersSheetOpen) return;
    setState(() => _isReadyOrdersSheetOpen = true);
    final picked = await showReadyOrdersSheet(
      context: context,
      orders: _readyOrders,
      formatCurrency: _formatCurrency,
    );
    if (mounted) {
      setState(() => _isReadyOrdersSheetOpen = false);
    }
    if (picked == null || !mounted) return;
    _pullOrderIntoCheckout(picked);
  }

  void _pullOrderIntoCheckout(ReadyOrder order) {
    _selectTab(CheckoutTab.keypad);
    _primeAmountWith(order.price);
    showSuccessSnackbar('${order.deviceModel} pulled into checkout');
  }

  Future<String?> _resolveShopkeeperId() async {
    var userId = _authCtrl.user.value?.id ?? '';
    if (userId.isEmpty) {
      userId = _profileCtrl.userId;
    }
    if (userId.isEmpty) {
      await _profileCtrl.fetchProfile();
      userId = _profileCtrl.userId;
    }
    return userId.trim().isEmpty ? null : userId.trim();
  }

  Future<void> _refreshPage() async {
    await Future.wait([
      _stockCtrl.fetchCategories(),
      _fetchInventory(),
      _fetchReadyOrders(),
    ]);
  }

  Future<void> _fetchInventory() async {
    if (mounted) {
      setState(() {
        _isInventoryLoading = true;
        _inventoryError = '';
      });
    }

    try {
      final shopkeeperId = await _resolveShopkeeperId();
      final items = shopkeeperId != null
          ? await _inventoryRepo.getByShopkeeperId(shopkeeperId)
          : await _inventoryRepo.getMyInventory();
      if (!mounted) return;
      setState(() => _inventoryItems = items);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _inventoryError =
            e.response?.data?['message']?.toString() ??
            'Failed to load products';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _inventoryError = 'Failed to load products');
    } finally {
      if (mounted) {
        setState(() => _isInventoryLoading = false);
      }
    }
  }

  double _effectivePrice(InventoryItem item) =>
      _priceOverrides[item.id] ?? item.price;

  /// Discount applied to [item] at checkout, or null when the price is
  /// untouched (or marked up).
  String? _discountLabel(InventoryItem item) {
    final discount = item.price - _effectivePrice(item);
    if (discount < 0.01) return null;

    final percent = item.price <= 0 ? 0.0 : discount / item.price * 100;
    final percentText = percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1);
    return '${_formatCurrency(discount)} off · $percentText%';
  }

  /// Total taken off across every edited product, ignoring mark-ups.
  double get _totalDiscount {
    return _inventoryItems.fold<double>(0, (sum, item) {
      final discount = item.price - _effectivePrice(item);
      return discount > 0 ? sum + discount : sum;
    });
  }

  int get _editedPriceCount => _inventoryItems
      .where((item) => _priceOverrides.containsKey(item.id))
      .length;

  Widget _buildPriceSummary() {
    if (_editedPriceCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: PriceOverrideSummary(
        count: _editedPriceCount,
        totalLabel: _formatCurrency(_totalDiscount),
        onReset: () => setState(_priceOverrides.clear),
      ),
    );
  }

  Future<void> _editPrice(InventoryItem item) async {
    final current = _effectivePrice(item);
    _priceCtrl.text = current % 1 == 0
        ? current.toStringAsFixed(0)
        : current.toStringAsFixed(2);
    _priceCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _priceCtrl.text.length,
    );

    final price = await showPriceEditSheet(
      context: context,
      controller: _priceCtrl,
      itemName: item.itemName,
      currencySymbol: _profileCtrl.currencySymbol,
      originalPrice: item.price,
    );
    if (price == null || !mounted) return;

    setState(() {
      // Matching the original price means the override is gone, not that it
      // is stored as a no-op.
      if ((price - item.price).abs() < 0.01) {
        _priceOverrides.remove(item.id);
      } else {
        _priceOverrides[item.id] = price;
      }
    });
  }

  Future<void> _addToCart(InventoryItem item) async {
    final shopkeeperId = await _resolveShopkeeperId();
    if (shopkeeperId == null) {
      showErrorSnackbar('Unable to find your profile');
      return;
    }

    try {
      await _cartRepo.addToCart(shopkeeperId: shopkeeperId, itemId: item.id);
      _primeAmountWith(_effectivePrice(item));
      showSuccessSnackbar('${item.itemName} added to basket');
    } on DioException catch (e) {
      showErrorSnackbar(
        e.response?.data?['message']?.toString() ??
            'Failed to add item to basket',
      );
    }
  }

  void _updateExpression(AmountExpression next) {
    HapticFeedback.selectionClick();
    setState(() => _expression = next);
  }

  void _appendDigit(String digit) =>
      _updateExpression(_expression.addDigit(digit));

  void _appendDecimal() => _updateExpression(_expression.addDecimal());

  void _appendOperator(String operator) =>
      _updateExpression(_expression.addOperator(operator));

  void _backspace() {
    HapticFeedback.lightImpact();
    setState(() => _expression = _expression.backspace());
  }

  void _primeAmountWith(double amount) {
    if (amount <= 0) return;
    setState(() => _expression = AmountExpression.fromValue(amount));
  }

  /// Evaluated total, or 0 while the expression cannot be resolved.
  double get _typedAmount => _expression.value ?? 0;

  bool get _hasTypedAmount => (_expression.value ?? 0) > 0;

  String get _searchQuery => _searchCtrl.text.trim().toLowerCase();

  List<InventoryItem> get _filteredItems {
    final query = _searchQuery;
    if (query.isEmpty) return _inventoryItems;

    return _inventoryItems.where((item) {
      final haystack = [
        item.itemName,
        item.brand,
        item.imeiNumber,
        item.modelNumber,
        item.storage,
        item.color,
        item.categoryName,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<Category> get _filteredCategories {
    final query = _searchQuery;
    final categories = _stockCtrl.inventoryCategoryCards.toList();
    if (query.isEmpty) return categories;

    return categories.where((category) {
      final haystack = '${category.name} ${category.itemCount}'.toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  /// Names the calculated lines before they reach the review screen.
  Future<void> _openCalculationNote() async {
    if (_expression.isEmpty) {
      showErrorSnackbar('Add an amount first');
      return;
    }
    HapticFeedback.selectionClick();

    final result = await Navigator.push<CalculationNoteResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CalculationNotePage(
          lines: _namedLines,
          initialNote: _calculationNote,
        ),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _lineNames
        ..clear()
        ..addEntries(
          result.lines
              .where((line) => line.name.isNotEmpty)
              .map((line) => MapEntry(line.expression, line.name)),
        );
      _calculationNote = result.note;
    });
  }

  /// Opens the item-by-item review of everything typed into the calculator.
  Future<void> _openQuantityReview() async {
    if (_expression.isEmpty) {
      showErrorSnackbar('Add an amount first');
      return;
    }
    HapticFeedback.selectionClick();
    final shopkeeperId = await _resolveShopkeeperId() ?? '';
    if (!mounted) return;

    await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => QuantityReviewPage(
          lines: _namedLines,
          currencySymbol: _profileCtrl.currencySymbol,
          shopkeeperId: shopkeeperId,
        ),
      ),
    );
  }

  /// Calculator lines with any names the shopkeeper has given them.
  List<CalculationLine> get _namedLines => [
    for (final line in _expression.lines)
      line.copyWith(name: _lineNames[line.expression] ?? ''),
  ];

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(() => _expression = _expression.cleared());
  }

  static final _groupPattern = RegExp(r'(\d)(?=(\d{3})+(?!\d))');

  String _formatNumber(num value) {
    final hasFraction = value % 1 != 0;
    final text = value.toStringAsFixed(hasFraction ? 2 : 0);
    final parts = text.split('.');
    final whole = parts.first.replaceAllMapped(
      _groupPattern,
      (match) => '${match[1]},',
    );
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }

  String _formatCurrency(num value) {
    return '${_profileCtrl.currencySymbol}${_formatNumber(value)}';
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Obx(() {
        // Rebuild on both inventory refreshes and palette (light/dark) changes.
        _stockCtrl.isLoading.value;
        if (Get.isRegistered<ProfileThemeController>()) {
          Get.find<ProfileThemeController>().selectedTheme.value;
        }

        return Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: ReadyOrdersCard(
                orders: _readyOrders,
                onToggleVisibility: _openReadyOrders,
                isSheetVisible: _isReadyOrdersSheetOpen,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: CheckoutTabBar(
                selected: _selectedTab,
                onChanged: _selectTab,
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                child: switch (_selectedTab) {
                  CheckoutTab.keypad => _buildKeypadTab(),
                  CheckoutTab.inventory => _buildInventoryTab(),
                  CheckoutTab.allProducts => _buildProductsTab(),
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Checkout',
              style: CheckoutTokens.text(
                size: 22,
                weight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          CheckoutIconButton(
            icon: Icons.qr_code_scanner_rounded,
            isAccent: true,
            onTap: () => _selectTab(CheckoutTab.allProducts),
          ),
          const SizedBox(width: 10),
          CheckoutIconButton(
            icon: Icons.menu_rounded,
            onTap: () => _showCategoryMenu(context),
          ),
        ],
      ),
    );
  }

  /// The keypad tab has no section header, so the search toggle would be
  /// unreachable there - close it on the way in.
  void _selectTab(CheckoutTab tab) {
    setState(() {
      _selectedTab = tab;
      if (tab == CheckoutTab.keypad && _isSearchOpen) {
        _isSearchOpen = false;
        _searchCtrl.clear();
        FocusScope.of(context).unfocus();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchCtrl.clear();
        FocusScope.of(context).unfocus();
      }
    });
  }

  /// Scans a barcode, IMEI or serial straight into the search field.
  Future<void> _scanIntoSearch() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (code == null || code.trim().isEmpty || !mounted) return;
    setState(() => _searchCtrl.text = code.trim());
  }

  /// Slides in directly beneath the section title when search is toggled on.
  Widget _buildInlineSearch() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _isSearchOpen
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: CheckoutSearchField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                onClear: _toggleSearch,
                onScan: _scanIntoSearch,
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }

  Widget _buildKeypadTab() {
    return RefreshIndicator(
      color: CheckoutTokens.accent,
      backgroundColor: CheckoutTokens.surface,
      onRefresh: _refreshPage,
      child: ListView(
        key: const ValueKey('keypad'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 14, bottom: 100),
        children: [
          CheckoutAmountCard(
            amountText: _expression.value == null
                ? '--'
                : _formatNumber(_typedAmount),
            expressionText: _expression.display,
            showExpression: _expression.hasOperation,
            hasAmount: _hasTypedAmount,
            onClear: _clearAll,
            onNote: _openCalculationNote,
          ),
          const SizedBox(height: 8),
          CheckoutKeypad(
            onDigit: _appendDigit,
            onDecimal: _appendDecimal,
            onOperator: _appendOperator,
            onBackspace: _backspace,
            activeOperator: _expression.pendingOperator,
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: CheckoutTotalQtyButton(
              quantity: _expression.totalQuantity,
              onTap: _openQuantityReview,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    final categories = _filteredCategories;
    final topProducts = _filteredItems.take(4).toList();

    return RefreshIndicator(
      color: CheckoutTokens.accent,
      backgroundColor: CheckoutTokens.surface,
      onRefresh: _refreshPage,
      child: ListView(
        key: const ValueKey('inventory'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _listPadding,
        children: [
          CheckoutSectionHeader(
            title: 'Inventory categories',
            onSearchTap: _toggleSearch,
            isSearchOpen: _isSearchOpen,
          ),
          _buildInlineSearch(),
          _buildPriceSummary(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InventoryStatChip(
                icon: Icons.category_rounded,
                label: '${categories.length} categories',
              ),
              _InventoryStatChip(
                icon: Icons.inventory_2_rounded,
                label: '${_filteredItems.length} products',
              ),
              _InventoryStatChip(
                icon: Icons.add_box_rounded,
                label: 'Add new device',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddNewDevicePage()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (categories.isEmpty)
            const CheckoutEmptyPanel(
              icon: Icons.category_outlined,
              title: 'No inventory categories yet',
              subtitle: 'Add a category or device to build your inventory.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.18,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return CheckoutShortcutCard(
                  title: category.name,
                  subtitle: '${category.itemCount} items',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryScreen(
                        initialCategoryId: category.id,
                        initialCategoryName: category.name,
                      ),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 22),
          const CheckoutSectionHeader(title: 'Inventory quick picks'),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            const CheckoutEmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: 'No inventory products',
              subtitle: 'Your first few products will appear here.',
            )
          else
            ...topProducts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CheckoutProductRow(
                  item: item,
                  priceLabel: _formatCurrency(_effectivePrice(item)),
                  originalPriceLabel: _priceOverrides.containsKey(item.id)
                      ? _formatCurrency(item.price)
                      : null,
                  discountLabel: _discountLabel(item),
                  onAdd: () => _addToCart(item),
                  onEditPrice: () => _editPrice(item),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final items = _filteredItems;

    return RefreshIndicator(
      color: CheckoutTokens.accent,
      backgroundColor: CheckoutTokens.surface,
      onRefresh: _refreshPage,
      child: ListView(
        key: const ValueKey('products'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: _listPadding,
        children: [
          CheckoutSectionHeader(
            title: 'All products',
            onSearchTap: _toggleSearch,
            isSearchOpen: _isSearchOpen,
          ),
          _buildInlineSearch(),
          _buildPriceSummary(),
          const SizedBox(height: 12),
          if (_isInventoryLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: CircularProgressIndicator(color: CheckoutTokens.accent),
              ),
            )
          else if (_inventoryError.isNotEmpty)
            CheckoutEmptyPanel(
              icon: Icons.wifi_tethering_error_rounded,
              title: 'Could not load products',
              subtitle: _inventoryError,
            )
          else if (items.isEmpty)
            const CheckoutEmptyPanel(
              icon: Icons.search_off_rounded,
              title: 'Nothing matched',
              subtitle: 'Try a different search or add a new device.',
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CheckoutProductRow(
                  item: item,
                  priceLabel: _formatCurrency(_effectivePrice(item)),
                  originalPriceLabel: _priceOverrides.containsKey(item.id)
                      ? _formatCurrency(item.price)
                      : null,
                  discountLabel: _discountLabel(item),
                  onAdd: () => _addToCart(item),
                  onEditPrice: () => _editPrice(item),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCategoryMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'category_menu',
      barrierColor: AppColors.modalBarrier,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, _) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return SlideTransition(
          position: slide,
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.74,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    left: BorderSide(color: CheckoutTokens.border),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: CheckoutIconButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('CHECKOUT TOOLS', style: CheckoutTokens.label),
                    const SizedBox(height: 14),
                    _buildMenuOption(
                      context,
                      Icons.create_new_folder_rounded,
                      'Add New Category',
                      () {
                        Navigator.pop(context);
                        showAddCategorySheet(context);
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuOption(
                      context,
                      Icons.add_box_rounded,
                      'Add New Device',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AddNewDevicePage()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuOption(
                      context,
                      Icons.category_rounded,
                      'Manage Categories',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageCategoriesPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuOption(
                      context,
                      Icons.inventory_rounded,
                      'View Inventory',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => InventoryScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildMenuOption(
                      context,
                      Icons.local_shipping_rounded,
                      'Suppliers',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupplierPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: CheckoutTokens.surface,
            borderRadius: BorderRadius.circular(18),
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
                child: Icon(icon, size: 17, color: CheckoutTokens.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
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

class _InventoryStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _InventoryStatChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: CheckoutTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CheckoutTokens.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: CheckoutTokens.accent),
              const SizedBox(width: 7),
              Text(
                label,
                style: CheckoutTokens.text(size: 12, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
