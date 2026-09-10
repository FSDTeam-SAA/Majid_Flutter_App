import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../customer/data/repositories/customer_repository_impl.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../scan/presentation/widgets/searchable_picker_sheet.dart';
import '../../../invoice/presentation/pages/invoice_page.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../controller/stock_basket_controller.dart';
import '../theme/checkout_tokens.dart';
import '../widgets/checkout_empty_panel.dart';
import '../widgets/checkout_icon_button.dart';

/// Last stop before payment for items picked out of the Stock section.
///
/// The shopkeeper can edit the selling price of every line here; the discount
/// and its percentage are worked out against the original stock price, which
/// is exactly what the client asked for ("let shopkeeper change prices and
/// show percentage how much discounted added").
class StockCheckoutReviewPage extends StatefulWidget {
  const StockCheckoutReviewPage({super.key});

  @override
  State<StockCheckoutReviewPage> createState() =>
      _StockCheckoutReviewPageState();
}

class _StockCheckoutReviewPageState extends State<StockCheckoutReviewPage> {
  late final StockBasketController _basket;
  final Map<String, TextEditingController> _priceControllers = {};

  /// Customer selection is optional here, and select-only: the client asked
  /// for the Create New Customer option to be removed from this screen.
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _basket = StockBasketController.instance;
    for (final line in _basket.lines) {
      _priceControllers[line.item.id] = TextEditingController(
        text: _plain(line.newPrice),
      );
    }
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    final profile = Get.find<ProfileController>();
    setState(() => _isLoadingCustomers = true);
    try {
      if (profile.userId.isEmpty) await profile.fetchProfile();
      if (profile.userId.isEmpty) return;
      final customers = await CustomerRepositoryImpl(
        ApiClient(baseUrl),
      ).getCustomers(profile.userId);
      if (!mounted) return;
      setState(() => _customers = customers);
    } catch (_) {
      // Choosing a customer is optional, so a failed fetch leaves the row
      // empty rather than blocking the review.
    } finally {
      if (mounted) setState(() => _isLoadingCustomers = false);
    }
  }

  Future<void> _pickCustomer() async {
    if (_customers.isEmpty) {
      showErrorSnackbar('No saved customers to choose from');
      return;
    }
    final picked = await showSearchablePicker<Customer>(
      context: context,
      title: 'Choose customer',
      searchHint: 'Search name, phone or email',
      emptyMessage: 'No customers match',
      options: [
        for (final customer in _customers)
          PickerOption(
            value: customer,
            title: customer.fullName.isEmpty ? 'Customer' : customer.fullName,
            subtitle: [
              customer.phone,
              customer.email,
            ].where((value) => value.trim().isNotEmpty).join(' • '),
          ),
      ],
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedCustomer = picked);
  }

  @override
  void dispose() {
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _currency => Get.find<ProfileController>().currencySymbol;

  void _onPriceChanged(String itemId, String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null || value < 0) return;
    _basket.updatePrice(itemId, value);
    setState(() {});
  }

  /// Hands the reviewed lines to the existing Create Invoice flow, which owns
  /// customer selection, the PDF and the payment record. Stock is decremented
  /// there, once payment actually completes.
  void _charge() {
    if (_basket.lines.isEmpty) return;

    final drafts = [
      for (final line in _basket.lines)
        InvoiceDraftPrefill(
          itemName: line.item.itemName,
          description: line.item.productDetails ?? '',
          color: line.item.color ?? '',
          condition: line.item.currentState,
          imeiSerial: line.item.imeiNumber,
          price: line.newPrice,
          quantity: line.quantity,
        ),
    ];

    final customerId = _selectedCustomer?.id;

    _basket.clear();
    showSuccessSnackbar('Items sent to invoice for payment');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => InvoicePage(
          initialDrafts: drafts,
          initialCustomerId: customerId,
        ),
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
                CheckoutIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Checkout Review',
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
          Expanded(
            child: Obx(() {
              if (_basket.lines.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(18),
                  child: CheckoutEmptyPanel(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Nothing to review',
                    subtitle: 'Add stock items and they will show up here.',
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  _banner(),
                  const SizedBox(height: 16),
                  _customerCard(),
                  const SizedBox(height: 16),
                  _itemsCard(),
                  const SizedBox(height: 16),
                  _summaryCard(),
                ],
              );
            }),
          ),
          Obx(() {
            if (_basket.lines.isEmpty) return const SizedBox.shrink();
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: _chargeButton(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CheckoutTokens.limeSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: CheckoutTokens.limeInk.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 22,
            color: CheckoutTokens.limeInk,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review items & prices',
                  style: CheckoutTokens.text(size: 15, weight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Review quantities, edit stock prices and confirm discounts '
                  'before payment.',
                  style: CheckoutTokens.text(
                    size: 12.5,
                    weight: FontWeight.w500,
                    color: CheckoutTokens.softText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Optional "Choose customer" row. No create-new action, by design.
  Widget _customerCard() {
    final selected = _selectedCustomer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickCustomer,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: CheckoutTokens.keySurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CheckoutTokens.keyEdge),
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 19,
                color: selected == null
                    ? CheckoutTokens.softText
                    : CheckoutTokens.limeInk,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose customer',
                      style: CheckoutTokens.text(
                        size: 11,
                        weight: FontWeight.w600,
                        color: CheckoutTokens.softText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected == null
                          ? (_isLoadingCustomers
                                ? 'Loading customers…'
                                : 'Optional — tap to select')
                          : selected.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CheckoutTokens.text(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedCustomer = null),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: CheckoutTokens.softText,
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: CheckoutTokens.softText,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CheckoutTokens.keySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CheckoutTokens.keyEdge),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Item name', style: CheckoutTokens.label)),
              SizedBox(
                width: 54,
                child: Text(
                  'Qty',
                  textAlign: TextAlign.center,
                  style: CheckoutTokens.label,
                ),
              ),
              SizedBox(
                width: 62,
                child: Text(
                  'Original',
                  textAlign: TextAlign.right,
                  style: CheckoutTokens.label,
                ),
              ),
              SizedBox(
                width: 96,
                child: Text(
                  'New price',
                  textAlign: TextAlign.right,
                  style: CheckoutTokens.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in _basket.lines) _row(line),
        ],
      ),
    );
  }

  Widget _row(StockBasketLine line) {
    final controller = _priceControllers.putIfAbsent(
      line.item.id,
      () => TextEditingController(text: _plain(line.newPrice)),
    );
    final percent = line.discountPercent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.item.itemName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CheckoutTokens.text(size: 13.5, weight: FontWeight.w700),
                ),
                if (percent != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: CheckoutTokens.limeSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${percent.toStringAsFixed(percent % 1 == 0 ? 0 : 1)}% OFF',
                      style: CheckoutTokens.text(
                        size: 10,
                        weight: FontWeight.w800,
                        color: CheckoutTokens.limeInk,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 54,
            child: Text(
              '${line.quantity}',
              textAlign: TextAlign.center,
              style: CheckoutTokens.text(size: 13.5, weight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 62,
            child: Text(
              '$_currency${_plain(line.originalPrice)}',
              textAlign: TextAlign.right,
              style: CheckoutTokens.text(
                size: 12.5,
                weight: FontWeight.w600,
                color: CheckoutTokens.softText,
              ).copyWith(decoration: TextDecoration.lineThrough),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 96,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => _onPriceChanged(line.item.id, value),
              textAlign: TextAlign.right,
              style: CheckoutTokens.text(size: 13.5, weight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: _currency,
                prefixStyle: CheckoutTokens.text(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: CheckoutTokens.softText,
                ),
                suffixIcon: Icon(
                  Icons.edit_rounded,
                  size: 13,
                  color: CheckoutTokens.softText,
                ),
                suffixIconConstraints: const BoxConstraints(minWidth: 24),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                filled: true,
                fillColor: CheckoutTokens.surfaceMuted,
                border: _border(CheckoutTokens.keyEdge),
                enabledBorder: _border(CheckoutTokens.keyEdge),
                focusedBorder: _border(CheckoutTokens.limeInk),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CheckoutTokens.keySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CheckoutTokens.keyEdge),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '$_currency${_plain(_basket.subtotal)}'),
          const SizedBox(height: 10),
          _summaryRow(
            'Discount',
            _basket.discountTotal > 0
                ? '-$_currency${_plain(_basket.discountTotal)}'
                : '$_currency${_plain(0)}',
            valueColor: _basket.discountTotal > 0
                ? CheckoutTokens.limeInk
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: CheckoutTokens.keyEdge),
          ),
          _summaryRow(
            'Total',
            '$_currency${_plain(_basket.total)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: CheckoutTokens.text(
            size: isTotal ? 15 : 13.5,
            weight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? null : CheckoutTokens.softText,
          ),
        ),
        Text(
          value,
          style: CheckoutTokens.text(
            size: isTotal ? 18 : 14,
            weight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _chargeButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _charge,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: CheckoutTokens.limeGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              'Charge $_currency${_plain(_basket.total)}',
              style: CheckoutTokens.text(
                size: 17,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color),
  );

  static String _plain(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
