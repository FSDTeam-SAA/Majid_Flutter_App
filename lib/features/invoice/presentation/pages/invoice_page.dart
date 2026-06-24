import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../controller/invoice_data.dart';
import '../widgets/invoice_input_field.dart';
import '../widgets/invoice_product_item.dart';
import '../widgets/shop_info_card.dart';
import '../../../profile/presentation/controller/profile_controller.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  late final ApiClient _api;
  late final ProfileController _profileCtrl;
  int _tabIndex = 0;
  String? _selectedCustomer;
  String? _selectedCustomerId;
  String? _selectedPaymentType;
  bool _paymentTypeOpen = false;
  bool _customerDropOpen = false;
  final Set<int> _selectedProducts = {};
  bool _isLoading = true;
  String _errorMessage = '';
  List<InvoiceProduct> _products = [];
  List<Map<String, dynamic>> _customers = [];

  double get _totalAmount =>
      _selectedProducts.fold(0, (sum, i) => sum + _products[i].price);

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _profileCtrl = Get.find<ProfileController>();
    _loadInvoiceData();
  }

  Future<void> _loadInvoiceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Future.wait([_fetchCustomers(), _fetchProducts()]);
      if (_selectedProducts.isEmpty && _products.isNotEmpty) {
        _selectedProducts.add(0);
      }
    } on DioException catch (e) {
      _errorMessage =
          e.response?.data?['message'] ?? 'Failed to load invoice data';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCustomers() async {
    var shopkeeperId = _profileCtrl.userId;
    if (shopkeeperId.isEmpty) {
      await _profileCtrl.fetchProfile();
      shopkeeperId = _profileCtrl.userId;
    }
    if (shopkeeperId.isEmpty) {
      _customers = [];
      return;
    }
    final res = await _api.get(CustomerEndpoints.byShopkeeper(shopkeeperId));
    final data = res.data['data'];
    if (data is! List) {
      throw const FormatException('Invalid customers response');
    }
    _customers = List<Map<String, dynamic>>.from(data);
  }

  Future<void> _fetchProducts() async {
    final res = await _api.get(InventoryEndpoints.myInventory);
    final data = res.data['data'];
    if (data is! List) {
      throw const FormatException('Invalid inventory response');
    }
    _products = data
        .whereType<Map>()
        .map((item) => _productFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  InvoiceProduct _productFromJson(Map<String, dynamic> item) {
    final price =
        (item['expectedPrice'] as num?)?.toDouble() ??
        (item['purchasePrice'] as num?)?.toDouble() ??
        0;
    return InvoiceProduct(
      id: item['_id']?.toString() ?? '',
      name:
          item['itemName']?.toString() ??
          item['brand']?.toString() ??
          'Inventory item',
      code: item['sku']?.toString() ?? item['imeiNumber']?.toString() ?? 'N/A',
      price: price,
      color: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Create Invoice', showBackButton: false),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 14),
                  _buildTabBar(),
                  SizedBox(height: 22),
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (_errorMessage.isNotEmpty)
                    _buildLoadError()
                  else if (_tabIndex == 0)
                    _buildCreateInvoiceTab(),
                  if (_tabIndex == 1)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Text(
                          'Purchase Invoice',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: _floatingNavClearance(context)),
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  double _floatingNavClearance(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + 72;
  }

  Widget _buildTabBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('Create Invoice', 0)),
          Expanded(child: _buildTab('Purchase Invoice', 1)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? AppColors.surfaceForeground
                  : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateInvoiceTab() {
    final customerNames = _customers.map(_customerLabel).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Information',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 14),
        _buildDropdown(
          _selectedCustomer,
          'Choose a customer',
          _customerDropOpen,
          (v) => setState(() {
            _selectedCustomer = v;
            _selectedCustomerId = _customers
                .firstWhereOrNull(
                  (customer) => _customerLabel(customer) == v,
                )?['_id']
                ?.toString();
            _customerDropOpen = false;
          }),
          () => setState(() => _customerDropOpen = !_customerDropOpen),
          customerNames,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: InvoiceInputField(hint: 'First Name')),
            SizedBox(width: 10),
            Expanded(child: InvoiceInputField(hint: 'Last Name')),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Email'),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Phone Number'),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Billing Address'),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                _selectedPaymentType,
                'Payment Type',
                _paymentTypeOpen,
                (v) => setState(() {
                  _selectedPaymentType = v;
                  _paymentTypeOpen = false;
                }),
                () => setState(() => _paymentTypeOpen = !_paymentTypeOpen),
                paymentTypes,
              ),
            ),
            SizedBox(width: 10),
            Expanded(child: InvoiceInputField(hint: 'Already Paid')),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer ID'),
        SizedBox(height: 14),
        ShopInfoCard(),
        SizedBox(height: 24),
        Text(
          'Products',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 14),
        _buildProductSearch(),
        SizedBox(height: 12),
        if (_products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No inventory products available',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ..._products.asMap().entries.map(
            (e) => InvoiceProductItem(
              product: e.value,
              isSelected: _selectedProducts.contains(e.key),
              onTap: () => setState(
                () => _selectedProducts.contains(e.key)
                    ? _selectedProducts.remove(e.key)
                    : _selectedProducts.add(e.key),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadInvoiceData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _customerLabel(Map<String, dynamic> customer) {
    final first = customer['firstName']?.toString() ?? '';
    final last = customer['lastName']?.toString() ?? '';
    final name = '$first $last'.trim();
    if (name.isNotEmpty) return name;
    return customer['name']?.toString() ??
        customer['email']?.toString() ??
        'Customer';
  }

  Widget _buildDropdown(
    String? selected,
    String hint,
    bool isOpen,
    void Function(String) onSelect,
    VoidCallback onToggle,
    List<String> items,
  ) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selected ?? hint,
                  style: TextStyle(
                    color: selected != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
            if (isOpen) ...[
              SizedBox(height: 8),
              ...items.map(
                (item) => GestureDetector(
                  onTap: () => onSelect(item),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.fieldBorder),
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearch() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
            child: TextField(
              style: TextStyle(color: AppColors.primary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: AppColors.primary, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.primary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              Text(
                'Category',
                style: TextStyle(
                  color: AppColors.surfaceForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.surfaceForeground,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.fieldBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL AMOUNT DUE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '£${_totalAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          AppButton(
            label: 'Send Invoice',
            onPressed: () {
              if (_selectedCustomerId == null || _selectedCustomerId!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please choose a customer.')),
                );
                return;
              }
              if (_selectedProducts.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a product.')),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Invoice API requires a generated PDF file before sending.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
