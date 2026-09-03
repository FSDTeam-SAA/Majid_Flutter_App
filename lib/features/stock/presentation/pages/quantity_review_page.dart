import 'package:flutter/material.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../customer/data/repositories/customer_repository_impl.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../domain/entities/calculation_line.dart';
import '../theme/checkout_tokens.dart';
import '../../../scan/presentation/widgets/searchable_picker_sheet.dart';

/// A stock item pulled into the checkout, whose selling price can be adjusted
/// before payment.
class ReviewStockItem {
  final String id;
  final String name;
  final int quantity;
  final double originalPrice;
  final double newPrice;

  const ReviewStockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.originalPrice,
    required this.newPrice,
  });

  double get discountPercent => originalPrice <= 0
      ? 0
      : ((originalPrice - newPrice) / originalPrice) * 100;

  ReviewStockItem copyWith({double? newPrice}) => ReviewStockItem(
    id: id,
    name: name,
    quantity: quantity,
    originalPrice: originalPrice,
    newPrice: newPrice ?? this.newPrice,
  );
}

/// Last stop before payment: every quantity and price in one list, with the
/// discount worked out from the original stock price.
class QuantityReviewPage extends StatefulWidget {
  final List<CalculationLine> lines;
  final List<ReviewStockItem> stockItems;
  final String currencySymbol;

  /// Shopkeeper id, used to load the customer list. When empty the Choose
  /// Customer row still shows but has nothing to search.
  final String shopkeeperId;

  const QuantityReviewPage({
    super.key,
    required this.lines,
    required this.currencySymbol,
    this.stockItems = const [],
    this.shopkeeperId = '',
  });

  @override
  State<QuantityReviewPage> createState() => _QuantityReviewPageState();
}

class _QuantityReviewPageState extends State<QuantityReviewPage> {
  late final List<ReviewStockItem> _stock = [...widget.stockItems];
  late final List<TextEditingController> _priceControllers = [
    for (final item in _stock)
      TextEditingController(text: _plain(item.newPrice)),
  ];

  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (widget.shopkeeperId.trim().isEmpty) return;
    setState(() => _isLoadingCustomers = true);
    try {
      final customers = await CustomerRepositoryImpl(
        ApiClient(baseUrl),
      ).getCustomers(widget.shopkeeperId);
      if (!mounted) return;
      setState(() => _customers = customers);
    } catch (_) {
      // Choose Customer is optional, so a failed fetch just leaves it empty
      // rather than blocking the review screen.
    } finally {
      if (mounted) setState(() => _isLoadingCustomers = false);
    }
  }

  /// Select-only, on purpose: the spec asks for the Create New Customer
  /// option to be removed from this screen.
  Future<void> _pickCustomer() async {
    if (_customers.isEmpty) return;
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
            ].where((v) => v.trim().isNotEmpty).join(' • '),
          ),
      ],
    );
    if (!mounted) return;
    setState(() => _selectedCustomer = picked ?? _selectedCustomer);
  }

  @override
  void dispose() {
    for (final controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int get _totalQuantity {
    final fromLines = widget.lines.fold<int>(0, (sum, l) => sum + l.quantity);
    final fromStock = _stock.fold<int>(0, (sum, s) => sum + s.quantity);
    return fromLines + fromStock;
  }

  double get _total {
    final fromLines = widget.lines.fold<double>(0, (sum, l) => sum + l.amount);
    final fromStock = _stock.fold<double>(
      0,
      (sum, s) => sum + s.newPrice * s.quantity,
    );
    return fromLines + fromStock;
  }

  void _updatePrice(int index, String raw) {
    final value = double.tryParse(raw.trim());
    if (value == null) return;
    setState(() => _stock[index] = _stock[index].copyWith(newPrice: value));
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Quantity Review'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              children: [
                _banner(),
                const SizedBox(height: 16),
                _customerCard(),
                const SizedBox(height: 16),
                _itemsCard(),
                const SizedBox(height: 16),
                _totalCard(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: _payButton(),
          ),
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

  /// "Choose Customer" - optional, select-only, matching the spec.
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
                                : 'Optional - tap to select')
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
                width: 78,
                child: Text(
                  'Quantity',
                  textAlign: TextAlign.center,
                  style: CheckoutTokens.label,
                ),
              ),
              SizedBox(
                width: 68,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: CheckoutTokens.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in widget.lines) _lineRow(line),
          for (var i = 0; i < _stock.length; i++) _stockRow(i),
        ],
      ),
    );
  }

  Widget _lineRow(CalculationLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.name.isEmpty ? line.expression : line.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CheckoutTokens.text(size: 14, weight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 78,
            child: Text(
              line.expression,
              textAlign: TextAlign.center,
              style: CheckoutTokens.text(
                size: 12.5,
                weight: FontWeight.w500,
                color: CheckoutTokens.softText,
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Text(
              '= ${_plain(line.amount)}',
              textAlign: TextAlign.right,
              style: CheckoutTokens.text(size: 14, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockRow(int index) {
    final item = _stock[index];
    final discount = item.discountPercent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CheckoutTokens.text(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qty: ${item.quantity}',
                      style: CheckoutTokens.text(
                        size: 12,
                        weight: FontWeight.w500,
                        color: CheckoutTokens.softText,
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
                    'Original price',
                    style: CheckoutTokens.text(
                      size: 10.5,
                      weight: FontWeight.w500,
                      color: CheckoutTokens.softText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.currencySymbol}${_plain(item.originalPrice)}',
                    style: CheckoutTokens.text(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: CheckoutTokens.softText,
                    ).copyWith(decoration: TextDecoration.lineThrough),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              SizedBox(width: 96, child: _priceField(index)),
              const SizedBox(width: 8),
              if (discount > 0.05)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: CheckoutTokens.limeSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${discount.toStringAsFixed(1)}%\nOFF',
                    textAlign: TextAlign.center,
                    style: CheckoutTokens.text(
                      size: 9.5,
                      weight: FontWeight.w800,
                      color: CheckoutTokens.limeInk,
                      height: 1.15,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceField(int index) {
    return TextField(
      controller: _priceControllers[index],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (value) => _updatePrice(index, value),
      textAlign: TextAlign.right,
      style: CheckoutTokens.text(size: 14, weight: FontWeight.w700),
      decoration: InputDecoration(
        prefixText: widget.currencySymbol,
        prefixStyle: CheckoutTokens.text(
          size: 13,
          weight: FontWeight.w600,
          color: CheckoutTokens.softText,
        ),
        suffixIcon: Icon(
          Icons.edit_rounded,
          size: 14,
          color: CheckoutTokens.softText,
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 26),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        filled: true,
        fillColor: CheckoutTokens.surfaceMuted,
        border: _border(CheckoutTokens.keyEdge),
        enabledBorder: _border(CheckoutTokens.keyEdge),
        focusedBorder: _border(CheckoutTokens.limeInk),
      ),
    );
  }

  Widget _totalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CheckoutTokens.keySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CheckoutTokens.keyEdge),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 22,
            color: CheckoutTokens.limeInk,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total items',
                  style: CheckoutTokens.text(size: 15, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sum of all quantities added',
                  style: CheckoutTokens.text(
                    size: 12,
                    weight: FontWeight.w500,
                    color: CheckoutTokens.softText,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Qty',
                style: CheckoutTokens.text(
                  size: 11,
                  weight: FontWeight.w600,
                  color: CheckoutTokens.limeInk,
                ),
              ),
              Text(
                '$_totalQuantity',
                style: CheckoutTokens.text(
                  size: 26,
                  weight: FontWeight.w800,
                  color: CheckoutTokens.limeInk,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _payButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, _total),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            gradient: CheckoutTokens.limeGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              'Pay ${widget.currencySymbol}${_plain(_total)}',
              style: CheckoutTokens.text(
                size: 17,
                weight: FontWeight.w700,
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
