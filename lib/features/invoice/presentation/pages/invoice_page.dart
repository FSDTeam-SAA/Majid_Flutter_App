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
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _customerIdCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  int _tabIndex = 0;
  String? _selectedCustomer;
  String? _selectedCustomerId;
  String? _selectedPaymentType;
  String? _selectedCategory;
  final Set<String> _selectedProductIds = {};
  bool _isLoading = true;
  bool _isCustomersLoading = false;
  bool _isCustomerDropdownOpen = false;
  String _errorMessage = '';
  List<InvoiceProduct> _products = [];
  List<Map<String, dynamic>> _customers = [];
  bool _isSendingInvoice = false;

  double get _totalAmount => _products
      .where((product) => _selectedProductIds.contains(product.id))
      .fold(0, (sum, product) => sum + product.price);

  List<String> get _categoryOptions {
    final categories =
        _products
            .map((product) => product.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return ['All', ...categories];
  }

  List<InvoiceProduct> get _filteredProducts {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _products.where((product) {
      final matchesCategory =
          _selectedCategory == null ||
          _selectedCategory == 'All' ||
          product.category == _selectedCategory;
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _profileCtrl = Get.find<ProfileController>();
    _loadInvoiceData();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _customerIdCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInvoiceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      await Future.wait([_fetchCustomers(), _fetchProducts()]);
      if (_selectedProductIds.isEmpty && _products.isNotEmpty) {
        _selectedProductIds.add(_products.first.id);
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

  Future<void> _openCustomerPicker() async {
    if (_isCustomersLoading) return;
    setState(() {
      _isCustomersLoading = true;
      _isCustomerDropdownOpen = true;
    });
    try {
      await _fetchCustomers();
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data?['message'] ?? 'Failed to load customers',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load customers')));
    } finally {
      if (mounted) setState(() => _isCustomersLoading = false);
    }
  }

  void _selectCustomer(String value) {
    final customer = _customers.firstWhereOrNull(
      (item) => _customerLabel(item) == value,
    );
    setState(() {
      _selectedCustomer = value;
      _selectedCustomerId = customer?['_id']?.toString();
      _applyCustomerData(customer);
      _isCustomerDropdownOpen = false;
    });
  }

  void _applyCustomerData(Map<String, dynamic>? customer) {
    _firstNameCtrl.text = customer?['firstName']?.toString() ?? '';
    _lastNameCtrl.text = customer?['lastName']?.toString() ?? '';
    _emailCtrl.text = customer?['email']?.toString() ?? '';
    _phoneCtrl.text =
        customer?['phone']?.toString() ??
        customer?['whatsappNumber']?.toString() ??
        '';
    _addressCtrl.text =
        customer?['billingAddress']?.toString() ??
        customer?['address']?.toString() ??
        '';
    _customerIdCtrl.text = customer?['_id']?.toString() ?? '';
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

  Future<void> _createInvoice() async {
    final hasExistingCustomer =
        _selectedCustomerId != null && _selectedCustomerId!.isNotEmpty;
    final hasManualCustomer = _firstNameCtrl.text.trim().isNotEmpty;

    if (!hasExistingCustomer && !hasManualCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a customer or fill in customer info.'),
        ),
      );
      return;
    }
    if (_selectedProductIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product.')));
      return;
    }

    setState(() => _isSendingInvoice = true);
    try {
      final items = _products
          .where((product) => _selectedProductIds.contains(product.id))
          .map(
            (product) => {
              'itemId': product.id,
              'name': product.name,
              'price': product.price,
              'quantity': 1,
            },
          )
          .toList();

      var shopkeeperId = _profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await _profileCtrl.fetchProfile();
        shopkeeperId = _profileCtrl.userId;
      }

      final data = <String, dynamic>{
        'shopkeeperId': shopkeeperId,
        'items': items,
        'totalAmount': _totalAmount,
        'paymentType': _selectedPaymentType ?? 'cash',
      };

      if (hasExistingCustomer) {
        data['customerId'] = _selectedCustomerId;
      } else {
        data['firstName'] = _firstNameCtrl.text.trim();
        data['lastName'] = _lastNameCtrl.text.trim();
        data['email'] = _emailCtrl.text.trim();
        data['phone'] = _phoneCtrl.text.trim();
        data['billingAddress'] = _addressCtrl.text.trim();
      }

      await _api.post(InvoiceEndpoints.create, data: data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created successfully!')),
      );
      setState(() {
        _selectedProductIds.clear();
        _selectedCustomer = null;
        _selectedCustomerId = null;
        _selectedPaymentType = null;
        _selectedCategory = null;
        _firstNameCtrl.clear();
        _lastNameCtrl.clear();
        _emailCtrl.clear();
        _phoneCtrl.clear();
        _addressCtrl.clear();
        _customerIdCtrl.clear();
        _searchCtrl.clear();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data?['message'] ?? 'Failed to create invoice',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create invoice')));
    } finally {
      if (mounted) setState(() => _isSendingInvoice = false);
    }
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
      category: _categoryFromJson(item),
    );
  }

  String _categoryFromJson(Map<String, dynamic> item) {
    final categoryName = item['categoryName'];
    if (categoryName is String && categoryName.trim().isNotEmpty) {
      return categoryName.trim();
    }

    final category = item['category'];
    if (category is Map && category['name'] != null) {
      return category['name'].toString();
    }

    final categoryId = item['categoryId'];
    if (categoryId is Map && categoryId['name'] != null) {
      return categoryId['name'].toString();
    }

    if (category is String && category.trim().isNotEmpty) {
      return category.trim();
    }

    return 'Uncategorized';
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
        _buildCustomerDropdown(),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(
                hint: 'First Name',
                controller: _firstNameCtrl,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InvoiceInputField(
                hint: 'Last Name',
                controller: _lastNameCtrl,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Email', controller: _emailCtrl),
        SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer Phone Number',
          controller: _phoneCtrl,
        ),
        SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer Billing Address',
          controller: _addressCtrl,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                context,
                _selectedPaymentType,
                'Payment Type',
                (v) => setState(() {
                  _selectedPaymentType = v;
                }),
                paymentTypes,
              ),
            ),
            SizedBox(width: 10),
            Expanded(child: InvoiceInputField(hint: 'Already Paid')),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer ID',
          controller: _customerIdCtrl,
          readOnly: true,
        ),
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
        else if (_filteredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No products match this filter',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ..._filteredProducts.map(
            (product) => InvoiceProductItem(
              product: product,
              isSelected: _selectedProductIds.contains(product.id),
              onTap: () => setState(
                () => _selectedProductIds.contains(product.id)
                    ? _selectedProductIds.remove(product.id)
                    : _selectedProductIds.add(product.id),
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

  Widget _buildCustomerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.primary, width: 1.2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: () {
              if (_isCustomerDropdownOpen) {
                setState(() => _isCustomerDropdownOpen = false);
              } else {
                _openCustomerPicker();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isCustomersLoading
                          ? 'Loading customers...'
                          : (_selectedCustomer ?? 'Choose a customer'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedCustomer != null && !_isCustomersLoading
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isCustomerDropdownOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isCustomerDropdownOpen) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: _buildCustomerDropdownMenu(),
          ),
        ],
      ],
    );
  }

  Widget _buildCustomerDropdownMenu() {
    if (_isCustomersLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_customers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No customers found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        children: _customers.map((customer) {
          final label = _customerLabel(customer);
          final isSelected = _selectedCustomer == label;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _selectCustomer(label),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.fieldBackground
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check, color: AppColors.primary, size: 18),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    String? selected,
    String hint,
    void Function(String) onSelect,
    List<String> items, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap:
          onTap ??
          () => _showSelectionSheet(
            context,
            title: hint,
            selected: selected,
            items: items,
            onSelect: onSelect,
          ),
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
                Expanded(
                  child: Text(
                    selected ?? hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSelectionSheet(
    BuildContext context, {
    required String title,
    required String? selected,
    required List<String> items,
    required void Function(String) onSelect,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      'No $title found',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ...items.map(
                  (item) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor: selected == item
                        ? AppColors.fieldBackground
                        : Colors.transparent,
                    title: Text(
                      item,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: selected == item
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: selected == item
                        ? Icon(Icons.check, color: AppColors.primary, size: 18)
                        : null,
                    onTap: () => Navigator.pop(sheetContext, item),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice != null) {
      onSelect(choice);
    }
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
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
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
        SizedBox(
          width: 118,
          child: _buildDropdown(
            context,
            _selectedCategory,
            'Category',
            (value) => setState(() {
              _selectedCategory = value == 'All' ? null : value;
            }),
            _categoryOptions,
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
            label: _isSendingInvoice ? 'Sending...' : 'Send Invoice',
            onPressed: _isSendingInvoice ? null : _createInvoice,
          ),
        ],
      ),
    );
  }
}
