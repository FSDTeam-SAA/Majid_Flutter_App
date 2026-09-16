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
import '../../domain/entities/ready_order.dart';
import '../controller/checkout_draft_controller.dart';
import '../controller/stock_basket_controller.dart';
import '../controller/stock_controller.dart';
import '../theme/checkout_tokens.dart';
import '../utils/amount_expression.dart';
import '../widgets/checkout_amount_card.dart';
import '../widgets/checkout_icon_button.dart';
import '../widgets/checkout_keypad.dart';
import '../widgets/checkout_total_qty_button.dart';
import '../widgets/ready_orders_card.dart';
import '../widgets/ready_orders_sheet.dart';
import '../../domain/entities/calculation_line.dart';
import 'calculation_note_page.dart';
import 'quantity_review_page.dart';
import 'add_category_sheet.dart';
import 'add_new_device_page.dart';
import 'inventory_screen.dart';
import 'manage_categories_page.dart';
import 'stock_categories_page.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  late final ApiClient _api;
  late final StockController _stockCtrl;
  late final StockBasketController _basket;
  late final ProfileController _profileCtrl;
  late final AuthController _authCtrl;

  final TextEditingController _searchCtrl = TextEditingController();
  bool _isReadyOrdersSheetOpen = false;
  List<ReadyOrder> _readyOrders = [];

  /// Keypad amounts, their names and any pulled-in repairs. Held outside this
  /// State because the bottom navigation disposes the page on every tab
  /// change, which used to wipe a half-rung-up sale.
  late final CheckoutDraftController _draft;

  AmountExpression get _expression => _draft.expression;

  @override
  void initState() {
    super.initState();
    final api = ApiClient(baseUrl);
    _api = api;
    _stockCtrl = Get.find<StockController>();
    _basket = StockBasketController.instance;
    _profileCtrl = Get.find<ProfileController>();
    _authCtrl = Get.find<AuthController>();
    _draft = CheckoutDraftController.instance;
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_stockCtrl.fetchCategories(), _fetchReadyOrders()]);
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
    setState(() => _draft.addRepair(order));
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
    await Future.wait([_stockCtrl.fetchCategories(), _fetchReadyOrders()]);
  }

  void _updateExpression(AmountExpression next) {
    HapticFeedback.selectionClick();
    setState(() => _draft.setExpression(next));
  }

  void _appendDigit(String digit) =>
      _updateExpression(_expression.addDigit(digit));

  void _appendDecimal() => _updateExpression(_expression.addDecimal());

  void _appendOperator(String operator) =>
      _updateExpression(_expression.addOperator(operator));

  void _backspace() {
    HapticFeedback.lightImpact();
    setState(() => _draft.setExpression(_expression.backspace()));
  }

  /// Evaluated total, or 0 while the expression cannot be resolved.
  double get _typedAmount => _expression.value ?? 0;

  bool get _hasTypedAmount => (_expression.value ?? 0) > 0;

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
        builder: (_) =>
            CalculationNotePage(lines: _namedLines, initialNote: _draft.note),
      ),
    );
    if (result == null || !mounted) return;

    setState(() {
      _draft.setLineNames({
        for (final line in result.lines)
          if (line.name.isNotEmpty) line.expression: line.name,
      });
      _draft.setNote(result.note);
    });
  }

  /// Opens one review containing stock, repairs and custom keypad charges.
  Future<void> _openQuantityReview() async {
    if (_totalQuantity == 0) {
      showErrorSnackbar('Add an item first');
      return;
    }
    HapticFeedback.selectionClick();
    final shopkeeperId = await _resolveShopkeeperId() ?? '';
    if (!mounted) return;

    await Navigator.push<double>(
      context,
      MaterialPageRoute(
        builder: (_) => QuantityReviewPage(
          lines: _combinedLines,
          stockItems: [
            for (final line in _basket.lines)
              ReviewStockItem(
                id: line.item.id,
                name: line.item.itemName,
                quantity: line.quantity,
                originalPrice: line.originalPrice,
                newPrice: line.newPrice,
              ),
          ],
          currencySymbol: _profileCtrl.currencySymbol,
          shopkeeperId: shopkeeperId,
          customerHint: _customerHint,
          onStockPriceChanged: _basket.updatePrice,
          onStockRemoved: _basket.remove,
          onClearAll: _clearCheckout,
          onLineRemoved: _removeCombinedLine,
        ),
      ),
    );
  }

  /// Empties the whole sale: stock basket, pulled-in repairs and the keypad.
  void _clearCheckout() {
    setState(_draft.clear);
    _basket.clear();
  }

  /// Mirrors a row removed on the review screen. [index] indexes
  /// [_combinedLines], so repairs come first and keypad terms follow.
  void _removeCombinedLine(int index) {
    setState(() => _draft.removeLineAt(index));
  }

  /// Customer of the first repair in this sale, if any. Repairs are the only
  /// part of the checkout that knows who is paying.
  CustomerHint? get _customerHint {
    if (_draft.repairs.isEmpty) return null;
    final order = _draft.repairs.values.first;
    final hint = CustomerHint(
      name: order.customerName,
      phone: order.customerPhone,
      email: order.customerEmail,
    );
    return hint.isEmpty ? null : hint;
  }

  /// Calculator lines with any names the shopkeeper has given them.
  List<CalculationLine> get _namedLines => _draft.namedLines;

  List<CalculationLine> get _combinedLines => _draft.combinedLines;

  int get _totalQuantity => _basket.totalQuantity + _draft.totalQuantity;

  void _clearAll() {
    HapticFeedback.mediumImpact();
    setState(_draft.clear);
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
        // Rebuild on inventory refreshes, palette (light/dark) changes and
        // the checkout draft coming back from storage.
        _stockCtrl.isLoading.value;
        _draft.revision.value;
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
            // The Inventory / All products segments were dropped; this is a
            // plain label now, and stock browsing lives in the Stock section
            // behind Quick Stock Access.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Keypad',
                  style: CheckoutTokens.text(size: 15, weight: FontWeight.w800),
                ),
              ),
            ),
            Expanded(child: _buildKeypadTab()),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: CheckoutTotalQtyButton(
                quantity: _totalQuantity,
                onTap: _openQuantityReview,
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
          // Only the separate scanner/QR shortcut came out of this header.
          // The three-line menu stays: it opens Quick Stock Access.
          CheckoutIconButton(
            icon: Icons.menu_rounded,
            onTap: () => _showCategoryMenu(context),
          ),
        ],
      ),
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
        padding: const EdgeInsets.only(top: 14, bottom: 16),
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
                    Text('QUICK STOCK ACCESS', style: CheckoutTokens.label),
                    const SizedBox(height: 14),
                    _buildMenuOption(
                      context,
                      Icons.widgets_rounded,
                      'Stock Categories',
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StockCategoriesPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
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
