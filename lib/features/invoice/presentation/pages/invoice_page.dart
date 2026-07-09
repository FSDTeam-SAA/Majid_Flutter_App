import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../controller/invoice_data.dart';
import '../utils/invoice_pdf_builder.dart';
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
  static const double _pageLoaderSize = 28;
  static const double _dropdownLoaderSize = 22;

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

  // Purchase Invoice
  final _pFirstNameCtrl = TextEditingController();
  final _pLastNameCtrl = TextEditingController();
  final _pEmailCtrl = TextEditingController();
  final _pPhoneCtrl = TextEditingController();
  final _pAddressCtrl = TextEditingController();
  final _pIdNumberCtrl = TextEditingController();
  final _pCustomerNameCtrl = TextEditingController();
  final List<_PurchaseItem> _purchaseItems = [_PurchaseItem()];
  bool _isSendingPurchase = false;
  File? _nidFrontImage;
  File? _nidBackImage;
  bool _isExtractingNid = false;

  // Delivery Invoice
  final _dFirstNameCtrl = TextEditingController();
  final _dLastNameCtrl = TextEditingController();
  final _dEmailCtrl = TextEditingController();
  final _dPhoneCtrl = TextEditingController();
  final _dAddressCtrl = TextEditingController();
  final List<_PurchaseItem> _deliveryItems = [_PurchaseItem()];
  bool _isSendingDelivery = false;

  // View Invoices
  bool _isViewInvoicesLoaded = false;
  bool _isViewInvoicesLoading = false;
  String _viewInvoicesError = '';
  List<Map<String, dynamic>> _viewInvoices = [];

  double get _totalAmount =>
      _products.where((product) => _selectedProductIds.contains(product.id)).fold(0, (sum, product) => sum + product.price);

  List<String> get _categoryOptions {
    final categories = _products.map((product) => product.category.trim()).where((category) => category.isNotEmpty).toSet().toList()
      ..sort();
    return ['All', ...categories];
  }

  List<InvoiceProduct> get _filteredProducts {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _products.where((product) {
      final matchesCategory = _selectedCategory == null || _selectedCategory == 'All' || product.category == _selectedCategory;
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
    _pFirstNameCtrl.dispose();
    _pLastNameCtrl.dispose();
    _pEmailCtrl.dispose();
    _pPhoneCtrl.dispose();
    _pAddressCtrl.dispose();
    _pIdNumberCtrl.dispose();
    _pCustomerNameCtrl.dispose();
    for (final item in _purchaseItems) {
      item.dispose();
    }
    _dFirstNameCtrl.dispose();
    _dLastNameCtrl.dispose();
    _dEmailCtrl.dispose();
    _dPhoneCtrl.dispose();
    _dAddressCtrl.dispose();
    for (final item in _deliveryItems) {
      item.dispose();
    }
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
      _errorMessage = e.response?.data?['message'] ?? 'Failed to load invoice data';
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
      showErrorSnackbar(e.response?.data?['message'] ?? 'Failed to load customers');
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar('Failed to load customers');
    } finally {
      if (mounted) setState(() => _isCustomersLoading = false);
    }
  }

  void _selectCustomer(String value) {
    final customer = _customers.firstWhereOrNull((item) => _customerLabel(item) == value);
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
    _phoneCtrl.text = customer?['phone']?.toString() ?? customer?['whatsappNumber']?.toString() ?? '';
    _addressCtrl.text = customer?['billingAddress']?.toString() ?? customer?['address']?.toString() ?? '';
    _customerIdCtrl.text = customer?['_id']?.toString() ?? '';
  }

  Future<void> _fetchProducts() async {
    final res = await _api.get(InventoryEndpoints.myInventory);
    final data = res.data['data'];
    if (data is! List) {
      throw const FormatException('Invalid inventory response');
    }
    _products = data.whereType<Map>().map((item) => _productFromJson(Map<String, dynamic>.from(item))).toList();
  }

  Future<void> _createInvoice() async {
    final hasExistingCustomer = _selectedCustomerId != null && _selectedCustomerId!.isNotEmpty;
    final hasManualCustomer = _firstNameCtrl.text.trim().isNotEmpty;

    if (!hasExistingCustomer && !hasManualCustomer) {
      showErrorSnackbar('Please choose a customer or fill in customer info.');
      return;
    }
    if (_selectedProductIds.isEmpty) {
      showErrorSnackbar('Please select a product.');
      return;
    }

    setState(() => _isSendingInvoice = true);
    try {
      final selectedProducts = _products.where((product) => _selectedProductIds.contains(product.id)).toList();
      var shopkeeperId = _profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await _profileCtrl.fetchProfile();
        shopkeeperId = _profileCtrl.userId;
      }

      final now = DateTime.now();
      final customerFirstName = _firstNameCtrl.text.trim();
      final customerLastName = _lastNameCtrl.text.trim();
      final customerName = [customerFirstName, customerLastName].where((value) => value.isNotEmpty).join(' ');
      final paymentType = _selectedPaymentType ?? 'cash';
      final pdfFile = await InvoicePdfBuilder.build(
        fileNamePrefix: 'invoice',
        invoiceTitle: 'SALES INVOICE',
        invoiceNumber: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        shopName: _profileCtrl.shopName,
        shopAddress: _profileCtrl.shopAddress,
        shopEmail: _profileCtrl.email,
        shopPhone: _profileCtrl.whatsappNumber.isNotEmpty ? _profileCtrl.whatsappNumber : _profileCtrl.phone,
        customerName: customerName,
        customerEmail: _emailCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerAddress: _addressCtrl.text.trim(),
        paymentType: paymentType,
        items: selectedProducts
            .map(
              (product) => InvoicePdfItem(
                name: product.name,
                code: product.code,
                imeiSerial: product.imeiSerial,
                quantity: 1,
                unitPrice: product.price,
              ),
            )
            .toList(),
        totalAmount: _totalAmount,
        footerNote: 'Generated from iMoScan invoice flow.',
      );

      String customerId;
      if (hasExistingCustomer) {
        customerId = _selectedCustomerId!;
      } else {
        final customerRes = await _api.post(
          CustomerEndpoints.create,
          data: {
            'shopkeeperId': shopkeeperId,
            'firstName': _firstNameCtrl.text.trim(),
            'lastName': _lastNameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'billingAddress': _addressCtrl.text.trim(),
          },
        );
        customerId = customerRes.data['data']?['_id']?.toString() ?? '';
        if (customerId.isEmpty) {
          showErrorSnackbar('Failed to create customer');
          return;
        }
      }

      final payload = FormData();
      payload.fields.addAll([
        MapEntry('shopkeeperId', shopkeeperId),
        MapEntry('type', 'sales'),
        MapEntry('totalAmount', _totalAmount.toString()),
        MapEntry('paymentMethod', paymentType),
        if (customerId.isNotEmpty) MapEntry('customerInfo', customerId),
      ]);

      for (final product in selectedProducts) {
        payload.fields.add(MapEntry('itemsIds', product.id));
      }

      payload.files.add(MapEntry('invoice', await MultipartFile.fromFile(pdfFile.path, filename: pdfFile.uri.pathSegments.last)));
      await _api.post(InvoiceEndpoints.create, data: payload);
      if (!mounted) return;
      showSuccessSnackbar('Invoice created successfully!');
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
      showErrorSnackbar(e.response?.data?['message'] ?? 'Failed to create invoice');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to create invoice');
    } finally {
      if (mounted) setState(() => _isSendingInvoice = false);
    }
  }

  InvoiceProduct _productFromJson(Map<String, dynamic> item) {
    final price = (item['expectedPrice'] as num?)?.toDouble() ?? (item['purchasePrice'] as num?)?.toDouble() ?? 0;
    return InvoiceProduct(
      id: item['_id']?.toString() ?? '',
      name: item['itemName']?.toString() ?? item['brand']?.toString() ?? 'Inventory item',
      code: item['sku']?.toString() ?? item['imeiNumber']?.toString() ?? 'N/A',
      imeiSerial: item['imeiNumber']?.toString() ?? item['serialNumber']?.toString() ?? '',
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

  Future<void> _fetchViewInvoices() async {
    setState(() {
      _isViewInvoicesLoading = true;
      _viewInvoicesError = '';
    });
    try {
      var shopkeeperId = _profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await _profileCtrl.fetchProfile();
        shopkeeperId = _profileCtrl.userId;
      }
      final res = await _api.get(InvoiceEndpoints.byShopkeeper(shopkeeperId));
      final data = res.data['data'];
      if (data is List) {
        _viewInvoices = List<Map<String, dynamic>>.from(data);
      }
      _isViewInvoicesLoaded = true;
    } on DioException catch (e) {
      _viewInvoicesError = e.response?.data?['message'] ?? 'Failed to load invoices';
    } catch (_) {
      _viewInvoicesError = 'Failed to load invoices';
    } finally {
      if (mounted) setState(() => _isViewInvoicesLoading = false);
    }
  }

  String _formatInvoiceDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    return '${date.day}/${date.month}/${date.year}';
  }

  String _invoiceCustomerName(Map<String, dynamic> invoice) {
    final info = invoice['customerInfo'];
    if (info is Map) {
      final first = info['firstName']?.toString() ?? '';
      final last = info['lastName']?.toString() ?? '';
      final name = '$first $last'.trim();
      if (name.isNotEmpty) return name;
      return info['email']?.toString() ?? 'Customer';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Create Invoice', showBackButton: false),
          Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 0), child: _buildTabBar()),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_tabIndex == 0 && _isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: SizedBox(
                          width: _pageLoaderSize,
                          height: _pageLoaderSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else if (_tabIndex == 0 && _errorMessage.isNotEmpty)
                    _buildLoadError()
                  else if (_tabIndex == 0)
                    _buildCreateInvoiceTab(),
                  if (_tabIndex == 1) _buildPurchaseInvoiceTab(),
                  if (_tabIndex == 2) _buildDeliveryInvoiceTab(),
                  if (_tabIndex == 3) _buildViewInvoicesTab(),
                  if (_tabIndex == 0 && !_isLoading && _errorMessage.isEmpty) SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const List<_InvoiceTabSpec> _tabSpecs = [
    _InvoiceTabSpec('Create', Icons.receipt_long_outlined),
    _InvoiceTabSpec('Purchase', Icons.shopping_bag_outlined),
    _InvoiceTabSpec('Delivery', Icons.local_shipping_outlined),
    _InvoiceTabSpec('View', Icons.history_rounded),
  ];

  Widget _buildTabBar() {
    final isDark = AppColors.isDark;
    final tabBg = isDark ? AppColors.cardBackground : Colors.white.withValues(alpha: 0.6);

    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: tabBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.fieldBorder : AppColors.primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          _tabSpecs.length,
          (index) => Expanded(child: _buildTab(_tabSpecs[index], index)),
        ),
      ),
    );
  }

  Widget _buildTab(_InvoiceTabSpec spec, int index) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _tabIndex = index);
        if (index == 3 && !_isViewInvoicesLoaded && !_isViewInvoicesLoading) {
          _fetchViewInvoices();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))] : null,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  spec.icon,
                  size: 16,
                  color: isActive ? AppColors.surfaceForeground : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  spec.label,
                  style: TextStyle(
                    color: isActive ? AppColors.surfaceForeground : AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
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
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 14),
        _buildCustomerDropdown(),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(hint: 'First Name', controller: _firstNameCtrl),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InvoiceInputField(hint: 'Last Name', controller: _lastNameCtrl),
            ),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Email', controller: _emailCtrl),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Phone Number', controller: _phoneCtrl),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Billing Address', controller: _addressCtrl),
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
        InvoiceInputField(hint: 'Customer ID', controller: _customerIdCtrl, readOnly: true),
        SizedBox(height: 14),
        ShopInfoCard(),
        SizedBox(height: 24),
        Text(
          'Products',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 14),
        _buildProductSearch(),
        SizedBox(height: 12),
        if (_products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No inventory products available', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else if (_filteredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No products match this filter', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ..._filteredProducts.map(
            (product) => InvoiceProductItem(
              product: product,
              isSelected: _selectedProductIds.contains(product.id),
              onTap: () => setState(
                () =>
                    _selectedProductIds.contains(product.id) ? _selectedProductIds.remove(product.id) : _selectedProductIds.add(product.id),
              ),
            ),
          ),

        _buildBottomBar(),
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
            OutlinedButton(onPressed: _loadInvoiceData, child: const Text('Retry')),
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
    return customer['name']?.toString() ?? customer['email']?.toString() ?? 'Customer';
  }

  Widget _buildCustomerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.primary.withValues(alpha: AppColors.isDark ? 0.6 : 0.72), width: 1.2),
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
                      _isCustomersLoading ? 'Loading customers...' : (_selectedCustomer ?? 'Choose a customer'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _selectedCustomer != null && !_isCustomersLoading ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_isCustomerDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: _dropdownLoaderSize,
            height: _dropdownLoaderSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (_customers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('No customers found', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
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
                color: isSelected ? AppColors.fieldBackground : Colors.transparent,
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
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected) Icon(Icons.check, color: AppColors.primary, size: 18),
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
      onTap: onTap ?? () => _showSelectionSheet(context, title: hint, selected: selected, items: items, onSelect: onSelect),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.primary.withValues(alpha: AppColors.isDark ? 0.6 : 0.72), width: 1.2),
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
                    style: TextStyle(color: selected != null ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 14),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text('No $title found', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ),
                ...items.map(
                  (item) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: selected == item ? AppColors.fieldBackground : Colors.transparent,
                    title: Text(
                      item,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: selected == item ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    trailing: selected == item ? Icon(Icons.check, color: AppColors.primary, size: 18) : null,
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
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.primary.withValues(alpha: AppColors.isDark ? 0.6 : 0.72), width: 1.2),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: AppColors.primary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: AppColors.primary, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
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

  double get _purchaseGrandTotal {
    double total = 0;
    for (final item in _purchaseItems) {
      final qty = int.tryParse(item.quantityCtrl.text.trim()) ?? 0;
      final price = double.tryParse(item.priceCtrl.text.trim()) ?? 0;
      total += qty * price;
    }
    return total;
  }

  Widget _buildPurchaseInvoiceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Information',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text('Identity validation framework controls', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(hint: 'First Name', controller: _pFirstNameCtrl),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InvoiceInputField(hint: 'Last Name', controller: _pLastNameCtrl),
            ),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Email', controller: _pEmailCtrl),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Phone Number', controller: _pPhoneCtrl),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Billing Address', controller: _pAddressCtrl),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer ID Number', controller: _pIdNumberCtrl),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(hint: 'Customer Name', controller: _pCustomerNameCtrl),
            ),
            SizedBox(width: 10),
            OutlinedButton(
              onPressed: _isExtractingNid ? null : _showCaptureNidSheet,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: _isExtractingNid
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.primary),
                    )
                  : Text('Capture NID'),
            ),
          ],
        ),
        SizedBox(height: 14),
        ShopInfoCard(),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Purchase Items',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure specifications and accumulate tracking logs',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: () => setState(() => _purchaseItems.add(_PurchaseItem())),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('Add Item', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        SizedBox(height: 14),
        ...List.generate(_purchaseItems.length, (i) => _buildPurchaseItemCard(i)),
        SizedBox(height: 20),
        AppButton(
          label: _isSendingPurchase ? 'Creating...' : 'Create Purchase Receipt',
          onPressed: _isSendingPurchase ? null : _createPurchaseInvoice,
        ),
        SizedBox(height: 100),
      ],
    );
  }

  Widget _buildPurchaseItemCard(int index) => _buildItemCard(_purchaseItems, index);

  Widget _buildItemCard(List<_PurchaseItem> items, int index) {
    final item = items[index];
    final qty = int.tryParse(item.quantityCtrl.text.trim()) ?? 0;
    final price = double.tryParse(item.priceCtrl.text.trim()) ?? 0;
    final subTotal = qty * price;

    final isDark = AppColors.isDark;
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackground : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.fieldBorder : const Color(0xFFE4E7EC)),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: const Color(0xFF6BA0C8).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEVICE #${index + 1}',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
              GestureDetector(
                onTap: () {
                  if (items.length > 1) {
                    setState(() {
                      items[index].dispose();
                      items.removeAt(index);
                    });
                  } else {
                    setState(() {
                      items[index].nameCtrl.clear();
                      items[index].storageCtrl.clear();
                      items[index].colorCtrl.clear();
                      items[index].conditionCtrl.clear();
                      items[index].quantityCtrl.text = '1';
                      items[index].priceCtrl.text = '0';
                    });
                  }
                },
                child: Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
              ),
            ],
          ),
          SizedBox(height: 12),
          InvoiceInputField(hint: 'Item Name*', controller: item.nameCtrl),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InvoiceInputField(hint: 'Storage', controller: item.storageCtrl),
              ),
              SizedBox(width: 10),
              Expanded(
                child: InvoiceInputField(hint: 'Color', controller: item.colorCtrl),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InvoiceInputField(hint: 'Condition', controller: item.conditionCtrl),
              ),
              SizedBox(width: 10),
              Expanded(
                child: InvoiceInputField(hint: 'Quantity', controller: item.quantityCtrl, keyboardType: TextInputType.number),
              ),
            ],
          ),
          SizedBox(height: 10),
          InvoiceInputField(hint: 'Price per Unit', controller: item.priceCtrl, keyboardType: TextInputType.number),
          SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item Calculation Sub Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                Text(
                  '£${subTotal.toStringAsFixed(2)}',
                  style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCaptureNidSheet() async {
    File? frontImage = _nidFrontImage;
    File? backImage = _nidBackImage;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capture NID', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Add a photo of the front (required) and back (optional) of the NID card.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                    const SizedBox(height: 18),
                    _buildNidImageTile(
                      label: 'Front of NID',
                      required: true,
                      image: frontImage,
                      onTap: () async {
                        final picked = await _pickNidImage();
                        if (picked != null) setSheetState(() => frontImage = picked);
                      },
                      onClear: frontImage == null ? null : () => setSheetState(() => frontImage = null),
                    ),
                    const SizedBox(height: 10),
                    _buildNidImageTile(
                      label: 'Back of NID (optional)',
                      required: false,
                      image: backImage,
                      onTap: () async {
                        final picked = await _pickNidImage();
                        if (picked != null) setSheetState(() => backImage = picked);
                      },
                      onClear: backImage == null ? null : () => setSheetState(() => backImage = null),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Extract NID',
                      onPressed: frontImage == null && backImage == null ? null : () => Navigator.pop(sheetCtx, true),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _nidFrontImage = frontImage;
        _nidBackImage = backImage;
      });
      await _extractNid();
    }
  }

  Widget _buildNidImageTile({
    required String label,
    required bool required,
    required File? image,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            if (image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(image, width: 44, height: 44, fit: BoxFit.cover),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                image != null ? 'Selected' : label,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, color: AppColors.dangerColor, size: 18),
              )
            else
              Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<File?> _pickNidImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<void> _extractNid() async {
    if (_nidFrontImage == null && _nidBackImage == null) return;

    setState(() => _isExtractingNid = true);
    try {
      final payload = FormData.fromMap({
        if (_nidFrontImage != null) 'nid_front': await MultipartFile.fromFile(_nidFrontImage!.path),
        if (_nidBackImage != null) 'nid_back': await MultipartFile.fromFile(_nidBackImage!.path),
      });
      final res = await _api.post(OcrEndpoints.extractNid, data: payload);
      final data = res.data['data'];
      final nidNumber = data is Map ? data['nidNumber']?.toString() : null;

      if (nidNumber == null || nidNumber.isEmpty) {
        showErrorSnackbar('No valid NID number found in the selected image.');
        return;
      }
      _pIdNumberCtrl.text = nidNumber;
      showSuccessSnackbar('NID number extracted successfully.');
    } on DioException catch (e) {
      showErrorSnackbar(e.response?.data?['message']?.toString() ?? 'Failed to extract NID from image.');
    } catch (_) {
      showErrorSnackbar('Failed to extract NID from image.');
    } finally {
      if (mounted) setState(() => _isExtractingNid = false);
    }
  }

  Future<void> _createPurchaseInvoice() async {
    if (_pFirstNameCtrl.text.trim().isEmpty) {
      showErrorSnackbar('Please enter customer first name');
      return;
    }
    final hasItems = _purchaseItems.any((item) => item.nameCtrl.text.trim().isNotEmpty);
    if (!hasItems) {
      showErrorSnackbar('Please add at least one item');
      return;
    }
    final grandTotal = _purchaseGrandTotal;

    setState(() => _isSendingPurchase = true);
    try {
      var shopkeeperId = _profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await _profileCtrl.fetchProfile();
        shopkeeperId = _profileCtrl.userId;
      }

      final now = DateTime.now();
      final customerName = [_pFirstNameCtrl.text.trim(), _pLastNameCtrl.text.trim()].where((v) => v.isNotEmpty).join(' ');

      final pdfItems = _purchaseItems
          .where((item) => item.nameCtrl.text.trim().isNotEmpty)
          .map(
            (item) => InvoicePdfItem(
              name: item.nameCtrl.text.trim(),
              code: [
                item.storageCtrl.text.trim(),
                item.colorCtrl.text.trim(),
                item.conditionCtrl.text.trim(),
              ].where((v) => v.isNotEmpty).join(' / '),
              quantity: int.tryParse(item.quantityCtrl.text.trim()) ?? 1,
              unitPrice: double.tryParse(item.priceCtrl.text.trim()) ?? 0,
            ),
          )
          .toList();

      final pdfFile = await InvoicePdfBuilder.build(
        fileNamePrefix: 'purchase_invoice',
        invoiceTitle: 'PURCHASE INVOICE',
        invoiceNumber: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        shopName: _profileCtrl.shopName,
        shopAddress: _profileCtrl.shopAddress,
        shopEmail: _profileCtrl.email,
        shopPhone: _profileCtrl.whatsappNumber.isNotEmpty ? _profileCtrl.whatsappNumber : _profileCtrl.phone,
        customerName: customerName,
        customerEmail: _pEmailCtrl.text.trim(),
        customerPhone: _pPhoneCtrl.text.trim(),
        customerAddress: _pAddressCtrl.text.trim(),
        paymentType: 'cash',
        items: pdfItems,
        totalAmount: grandTotal,
        footerNote: 'Purchase invoice generated from iMoScan.',
      );

      final payload = FormData();
      payload.fields.addAll([
        MapEntry('shopkeeperId', shopkeeperId),
        MapEntry('type', 'purchase'),
        MapEntry('totalAmount', grandTotal.toString()),
        MapEntry('paymentMethod', 'cash'),
      ]);
      payload.files.add(MapEntry('invoice', await MultipartFile.fromFile(pdfFile.path, filename: pdfFile.uri.pathSegments.last)));

      await _api.post(InvoiceEndpoints.create, data: payload);
      if (!mounted) return;
      showSuccessSnackbar('Purchase receipt created successfully!');
      setState(() {
        _pFirstNameCtrl.clear();
        _pLastNameCtrl.clear();
        _pEmailCtrl.clear();
        _pPhoneCtrl.clear();
        _pAddressCtrl.clear();
        _pIdNumberCtrl.clear();
        _pCustomerNameCtrl.clear();
        _nidFrontImage = null;
        _nidBackImage = null;
        for (final item in _purchaseItems) {
          item.dispose();
        }
        _purchaseItems.clear();
        _purchaseItems.add(_PurchaseItem());
      });
    } on DioException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(e.response?.data?['message'] ?? 'Failed to create purchase receipt');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to create purchase receipt');
    } finally {
      if (mounted) setState(() => _isSendingPurchase = false);
    }
  }

  double get _deliveryGrandTotal {
    double total = 0;
    for (final item in _deliveryItems) {
      final qty = int.tryParse(item.quantityCtrl.text.trim()) ?? 0;
      final price = double.tryParse(item.priceCtrl.text.trim()) ?? 0;
      total += qty * price;
    }
    return total;
  }

  Widget _buildDeliveryInvoiceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Information',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(hint: 'First Name', controller: _dFirstNameCtrl),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InvoiceInputField(hint: 'Last Name', controller: _dLastNameCtrl),
            ),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Email', controller: _dEmailCtrl),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Phone Number', controller: _dPhoneCtrl),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Delivery Address', controller: _dAddressCtrl),
        SizedBox(height: 14),
        ShopInfoCard(),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Items',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            OutlinedButton(
              onPressed: () => setState(() => _deliveryItems.add(_PurchaseItem())),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('Add Item', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        SizedBox(height: 14),
        ...List.generate(_deliveryItems.length, (i) => _buildItemCard(_deliveryItems, i)),
        SizedBox(height: 20),
        AppButton(
          label: _isSendingDelivery ? 'Creating...' : 'Create Delivery Invoice',
          onPressed: _isSendingDelivery ? null : _createDeliveryInvoice,
        ),
        SizedBox(height: 100),
      ],
    );
  }

  Future<void> _createDeliveryInvoice() async {
    if (_dFirstNameCtrl.text.trim().isEmpty) {
      showErrorSnackbar('Please enter customer first name');
      return;
    }
    final hasItems = _deliveryItems.any((item) => item.nameCtrl.text.trim().isNotEmpty);
    if (!hasItems) {
      showErrorSnackbar('Please add at least one item');
      return;
    }
    final grandTotal = _deliveryGrandTotal;

    setState(() => _isSendingDelivery = true);
    try {
      var shopkeeperId = _profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await _profileCtrl.fetchProfile();
        shopkeeperId = _profileCtrl.userId;
      }

      final now = DateTime.now();
      final customerName = [_dFirstNameCtrl.text.trim(), _dLastNameCtrl.text.trim()].where((v) => v.isNotEmpty).join(' ');

      final pdfItems = _deliveryItems
          .where((item) => item.nameCtrl.text.trim().isNotEmpty)
          .map(
            (item) => InvoicePdfItem(
              name: item.nameCtrl.text.trim(),
              code: [
                item.storageCtrl.text.trim(),
                item.colorCtrl.text.trim(),
                item.conditionCtrl.text.trim(),
              ].where((v) => v.isNotEmpty).join(' / '),
              quantity: int.tryParse(item.quantityCtrl.text.trim()) ?? 1,
              unitPrice: double.tryParse(item.priceCtrl.text.trim()) ?? 0,
            ),
          )
          .toList();

      final pdfFile = await InvoicePdfBuilder.build(
        fileNamePrefix: 'delivery_invoice',
        invoiceTitle: 'DELIVERY INVOICE',
        invoiceNumber: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        shopName: _profileCtrl.shopName,
        shopAddress: _profileCtrl.shopAddress,
        shopEmail: _profileCtrl.email,
        shopPhone: _profileCtrl.whatsappNumber.isNotEmpty ? _profileCtrl.whatsappNumber : _profileCtrl.phone,
        customerName: customerName,
        customerEmail: _dEmailCtrl.text.trim(),
        customerPhone: _dPhoneCtrl.text.trim(),
        customerAddress: _dAddressCtrl.text.trim(),
        paymentType: 'cash',
        items: pdfItems,
        totalAmount: grandTotal,
        footerNote: 'Delivery invoice generated from iMoScan.',
      );

      final payload = FormData();
      payload.fields.addAll([
        MapEntry('shopkeeperId', shopkeeperId),
        MapEntry('type', 'delivery'),
        MapEntry('totalAmount', grandTotal.toString()),
        MapEntry('paymentMethod', 'cash'),
      ]);
      payload.files.add(MapEntry('invoice', await MultipartFile.fromFile(pdfFile.path, filename: pdfFile.uri.pathSegments.last)));

      await _api.post(InvoiceEndpoints.create, data: payload);
      if (!mounted) return;
      showSuccessSnackbar('Delivery invoice created successfully!');
      setState(() {
        _dFirstNameCtrl.clear();
        _dLastNameCtrl.clear();
        _dEmailCtrl.clear();
        _dPhoneCtrl.clear();
        _dAddressCtrl.clear();
        for (final item in _deliveryItems) {
          item.dispose();
        }
        _deliveryItems.clear();
        _deliveryItems.add(_PurchaseItem());
      });
    } on DioException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(e.response?.data?['message'] ?? 'Failed to create delivery invoice');
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to create delivery invoice');
    } finally {
      if (mounted) setState(() => _isSendingDelivery = false);
    }
  }

  Widget _buildViewInvoicesTab() {
    if (_isViewInvoicesLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.primary),
        ),
      );
    }
    if (_viewInvoicesError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Text(_viewInvoicesError, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _fetchViewInvoices, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_viewInvoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text('No invoices yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Invoices',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text('${_viewInvoices.length} total', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        SizedBox(height: 14),
        ..._viewInvoices.map((inv) {
          final type = inv['type']?.toString() ?? 'invoice';
          final amount = (inv['totalAmount'] as num?)?.toDouble();
          final date = _formatInvoiceDate(inv['createdAt']?.toString());
          final customer = _invoiceCustomerName(inv);
          final invoiceFile = inv['invoice'];
          final pdfUrl = invoiceFile is Map ? invoiceFile['url']?.toString() : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (pdfUrl != null) {
                  showDialog(
                    context: context,
                    useSafeArea: false,
                    builder: (_) => _PdfViewerPage(url: pdfUrl, title: '${type[0].toUpperCase()}${type.substring(1)} Invoice'),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${type[0].toUpperCase()}${type.substring(1)} Invoice',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(customer, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (amount != null)
                          Text(
                            '£${amount.toStringAsFixed(2)}',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        if (date.isNotEmpty) Text(date, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppColors.cardBackground.withValues(alpha: 0.9),
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
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '£${_totalAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
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
                child: Icon(Icons.receipt_long_outlined, color: AppColors.textPrimary, size: 22),
              ),
            ],
          ),
          SizedBox(height: 12),
          AppButton(
            label: _isSendingInvoice ? 'Creating...' : 'Create Invoice',
            onPressed: _isSendingInvoice ? null : _createInvoice,
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const _PdfViewerPage({required this.url, required this.title});

  @override
  State<_PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<_PdfViewerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final viewerUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}';
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: AppColors.background,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.cardBackground,
          foregroundColor: AppColors.textPrimary,
          title: Text(widget.title, style: const TextStyle(fontSize: 16)),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) Center(child: CircularProgressIndicator(color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _InvoiceTabSpec {
  final String label;
  final IconData icon;

  const _InvoiceTabSpec(this.label, this.icon);
}

class _PurchaseItem {
  final nameCtrl = TextEditingController();
  final storageCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  final conditionCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController(text: '0');

  void dispose() {
    nameCtrl.dispose();
    storageCtrl.dispose();
    colorCtrl.dispose();
    conditionCtrl.dispose();
    quantityCtrl.dispose();
    priceCtrl.dispose();
  }
}
