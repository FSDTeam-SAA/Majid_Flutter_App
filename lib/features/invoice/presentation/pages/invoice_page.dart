import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../customer/data/repositories/customer_repository_impl.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../customer/domain/repositories/customer_repository.dart';
import '../../../customer/presentation/controller/customer_controller.dart';
import '../../../customer/presentation/widgets/add_customer_sheet.dart';
import '../../data/repositories/invoice_repository_impl.dart';
import '../../domain/entities/invoice.dart' as invoice_entity;
import '../../domain/repositories/invoice_repository.dart';
import '../controller/invoice_data.dart';
import '../utils/invoice_pdf_builder.dart';
import '../widgets/invoice_customer_picker.dart';
import '../widgets/new_item_name_dialog.dart';
import '../widgets/invoice_input_field.dart';
import '../widgets/shop_info_card.dart';
import 'record_payment_page.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../auth/presentation/controller/auth_controller.dart';
import '../../../auth/presentation/pages/login_screen_view.dart';
import '../../../transactions/data/repositories/cash_management_repository_impl.dart';
import '../../../transactions/domain/repositories/cash_management_repository.dart';

class InvoiceDraftPrefill {
  final String itemName;
  final String description;
  final String color;
  final String condition;
  final String imeiSerial;
  final String statusLabel;
  final double? price;

  const InvoiceDraftPrefill({
    required this.itemName,
    this.description = '',
    this.color = '',
    this.condition = '',
    this.imeiSerial = '',
    this.statusLabel = '',
    this.price,
  });
}

class InvoicePage extends StatefulWidget {
  final int initialTabIndex;
  final InvoiceDraftPrefill? initialDraft;

  const InvoicePage({super.key, this.initialTabIndex = 0, this.initialDraft});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  static const double _pageLoaderSize = 28;
  static const double _dropdownLoaderSize = 22;

  late final CustomerRepository _customerRepo;
  late final CustomerController _customerCtrl;
  late final InvoiceRepository _invoiceRepo;
  late final CashManagementRepository _cashRepo;
  late final ProfileController _profileCtrl;
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _customerSearchCtrl = TextEditingController();
  int _tabIndex = 0;
  String? _selectedCustomer;
  String? _selectedCustomerId;
  String? _recordedPaymentMethod;
  double? _recordedAmountPaid;
  final List<_CreateInvoiceItem> _createInvoiceItems = [_CreateInvoiceItem()];
  bool _isLoading = true;
  bool _isCustomersLoading = false;
  bool _isCustomerDropdownOpen = false;

  String? _selectedPurchaseCustomer;
  bool _isPurchaseCustomerDropdownOpen = false;
  final TextEditingController _purchaseCustomerSearchCtrl =
      TextEditingController();
  bool _purchaseAddToInventory = false;
  String? _purchaseCategory;

  String? _selectedDeliveryCustomer;
  bool _isDeliveryCustomerDropdownOpen = false;
  final TextEditingController _deliveryCustomerSearchCtrl =
      TextEditingController();
  String _errorMessage = '';
  bool _sessionExpired = false;
  List<InvoiceProduct> _products = [];
  List<Customer> _customers = [];
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
  double _availableCash = 0;
  bool _didApplyInitialDraft = false;
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
  List<invoice_entity.Invoice> _viewInvoices = [];

  double get _totalAmount {
    double total = 0;
    for (final item in _createInvoiceItems) {
      final qty = int.tryParse(item.quantityCtrl.text.trim()) ?? 0;
      final price = double.tryParse(item.priceCtrl.text.trim()) ?? 0;
      final discount = double.tryParse(item.discountCtrl.text.trim()) ?? 0;
      final tax = double.tryParse(item.taxCtrl.text.trim()) ?? 0;
      final line = (qty * price) - discount + tax;
      total += line < 0 ? 0 : line;
    }
    return total;
  }

  List<String> get _purchaseCategoryOptions {
    final categories =
        _products
            .map((product) => product.category.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  static const _itemStorageOptions = [
    '32GB',
    '64GB',
    '128GB',
    '256GB',
    '512GB',
    '1TB',
  ];

  static const _itemColorOptions = [
    'Black',
    'Midnight',
    'White',
    'Starlight',
    'Gray',
    'Silver',
    'Natural Titanium',
    'Rose Gold',
    'Gold',
    'Blue',
    'Sky Blue',
    'Green',
    'Teal',
    'Purple',
    'Pink',
    'Red',
    'Orange',
    'Yellow',
    'Brown',
    'Beige',
  ];

  static const _defaultConditionOptions = [
    'New',
    'Used',
    'Excellent',
    'Good',
    'Fair',
    'Low Risk • Activation',
  ];

  List<String> get _itemConditionOptions {
    final options = <String>{
      ..._defaultConditionOptions,
      ..._products
          .map((product) => product.condition.trim())
          .where((condition) => condition.isNotEmpty),
    }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return options;
  }

  List<InvoiceProduct> _searchableProducts(String query) {
    final normalized = query.trim().toLowerCase();
    final seen = <String>{};
    final matches = _products.where((product) {
      if (normalized.isEmpty) return true;
      final haystack = [
        product.name,
        product.code,
        product.category,
        product.storage,
        product.colorName,
      ].join(' ').toLowerCase();
      return haystack.contains(normalized);
    });

    return matches.where((product) {
        final key = product.name.trim().toLowerCase();
        return key.isNotEmpty && seen.add(key);
      }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  String _productPickerSubtitle(InvoiceProduct product) {
    return [
      if (product.category.trim().isNotEmpty) product.category.trim(),
      if (product.storage.trim().isNotEmpty) product.storage.trim(),
      if (product.colorName.trim().isNotEmpty) product.colorName.trim(),
    ].join(' • ');
  }

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex.clamp(0, _tabSpecs.length - 1);
    final api = ApiClient(baseUrl);
    _customerRepo = CustomerRepositoryImpl(api);
    _customerCtrl = Get.isRegistered<CustomerController>()
        ? Get.find<CustomerController>()
        : Get.put(CustomerController());
    _invoiceRepo = InvoiceRepositoryImpl(api);
    _cashRepo = CashManagementRepositoryImpl(api);
    _profileCtrl = Get.find<ProfileController>();
    _loadInvoiceData();
    if (_tabIndex == 3) {
      _fetchViewInvoices();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _customerSearchCtrl.dispose();
    _pFirstNameCtrl.dispose();
    _pLastNameCtrl.dispose();
    _pEmailCtrl.dispose();
    _pPhoneCtrl.dispose();
    _pAddressCtrl.dispose();
    _pIdNumberCtrl.dispose();
    _pCustomerNameCtrl.dispose();
    _purchaseCustomerSearchCtrl.dispose();
    for (final item in _purchaseItems) {
      item.dispose();
    }
    _dFirstNameCtrl.dispose();
    _dLastNameCtrl.dispose();
    _dEmailCtrl.dispose();
    _dPhoneCtrl.dispose();
    _dAddressCtrl.dispose();
    _deliveryCustomerSearchCtrl.dispose();
    for (final item in _deliveryItems) {
      item.dispose();
    }
    for (final item in _createInvoiceItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInvoiceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _sessionExpired = false;
    });
    try {
      await Future.wait([
        _fetchCustomers(),
        _fetchProducts(),
        _fetchAvailableCash(),
      ]);
      _applyInitialDraftIfNeeded();
    } on DioException catch (e) {
      _sessionExpired = e.response?.statusCode == 401;
      _errorMessage = _sessionExpired
          ? 'Your session has expired'
          : (e.response?.data?['message'] ?? 'Failed to load invoice data');
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAvailableCash() async {
    var shopkeeperId = _profileCtrl.userId;
    if (shopkeeperId.isEmpty) {
      await _profileCtrl.fetchProfile();
      shopkeeperId = _profileCtrl.userId;
    }
    if (shopkeeperId.isEmpty) {
      _availableCash = 0;
      return;
    }
    final cashData = await _cashRepo.getCashManagement(shopkeeperId);
    _availableCash = cashData?.cashInDrawer ?? 0;
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
    _customers = await _customerRepo.getCustomers(shopkeeperId);
  }

  Future<void> _openCustomerPicker() async {
    if (_isCustomersLoading) return;
    setState(() {
      _isCustomersLoading = true;
      _isCustomerDropdownOpen = true;
      _customerSearchCtrl.clear();
    });
    try {
      await _fetchCustomers();
    } on DioException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(
        e.response?.data?['message'] ?? 'Failed to load customers',
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar('Failed to load customers');
    } finally {
      if (mounted) setState(() => _isCustomersLoading = false);
    }
  }

  void _selectCustomer(Customer customer) {
    _customerSearchCtrl.clear();
    setState(() {
      _selectedCustomer = customerLabel(customer);
      _selectedCustomerId = customer.id;
      _applyCustomerData(customer);
      _isCustomerDropdownOpen = false;
    });
  }

  void _applyCustomerData(Customer? customer) {
    _applyCustomerDataTo(
      customer,
      firstName: _firstNameCtrl,
      lastName: _lastNameCtrl,
      email: _emailCtrl,
      phone: _phoneCtrl,
      address: _addressCtrl,
    );
  }

  void _applyCustomerDataTo(
    Customer? customer, {
    required TextEditingController firstName,
    required TextEditingController lastName,
    required TextEditingController email,
    required TextEditingController phone,
    required TextEditingController address,
  }) {
    firstName.text = customer?.firstName ?? '';
    lastName.text = customer?.lastName ?? '';
    email.text = customer?.email ?? '';
    phone.text = customer?.phone ?? '';
    address.text = customer?.address ?? '';
  }

  Future<void> _openPurchaseCustomerPicker() async {
    if (_isCustomersLoading) return;
    setState(() {
      _isCustomersLoading = true;
      _isPurchaseCustomerDropdownOpen = true;
      _purchaseCustomerSearchCtrl.clear();
    });
    try {
      await _fetchCustomers();
    } on DioException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(
        e.response?.data?['message'] ?? 'Failed to load customers',
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar('Failed to load customers');
    } finally {
      if (mounted) setState(() => _isCustomersLoading = false);
    }
  }

  void _selectPurchaseCustomer(Customer customer) {
    _purchaseCustomerSearchCtrl.clear();
    setState(() {
      _selectedPurchaseCustomer = customerLabel(customer);
      _applyCustomerDataTo(
        customer,
        firstName: _pFirstNameCtrl,
        lastName: _pLastNameCtrl,
        email: _pEmailCtrl,
        phone: _pPhoneCtrl,
        address: _pAddressCtrl,
      );
      _isPurchaseCustomerDropdownOpen = false;
    });
  }

  Future<void> _openDeliveryCustomerPicker() async {
    if (_isCustomersLoading) return;
    setState(() {
      _isCustomersLoading = true;
      _isDeliveryCustomerDropdownOpen = true;
      _deliveryCustomerSearchCtrl.clear();
    });
    try {
      await _fetchCustomers();
    } on DioException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(
        e.response?.data?['message'] ?? 'Failed to load customers',
      );
    } catch (_) {
      if (!mounted) return;
      showErrorSnackbar('Failed to load customers');
    } finally {
      if (mounted) setState(() => _isCustomersLoading = false);
    }
  }

  void _selectDeliveryCustomer(Customer customer) {
    _deliveryCustomerSearchCtrl.clear();
    setState(() {
      _selectedDeliveryCustomer = customerLabel(customer);
      _applyCustomerDataTo(
        customer,
        firstName: _dFirstNameCtrl,
        lastName: _dLastNameCtrl,
        email: _dEmailCtrl,
        phone: _dPhoneCtrl,
        address: _dAddressCtrl,
      );
      _isDeliveryCustomerDropdownOpen = false;
    });
  }

  Future<void> _addCustomerFromPicker(
    TextEditingController searchController,
    ValueChanged<Customer> onSelect,
  ) async {
    final saved = await showAddCustomerSheet(context, _customerCtrl);
    if (saved != true || !mounted) return;

    final savedCustomerId = _customerCtrl.customers.isNotEmpty
        ? _customerCtrl.customers.first.id
        : null;
    await _fetchCustomers();
    if (!mounted) return;

    searchController.clear();

    if (savedCustomerId != null) {
      for (final customer in _customers) {
        if (customer.id == savedCustomerId) {
          onSelect(customer);
          return;
        }
      }
    }

    setState(() {});
  }

  Future<void> _fetchProducts() async {
    _products = await _invoiceRepo.getInventoryItems();
  }

  InvoiceProduct? _findProductByName(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final product in _products) {
      if (product.name.trim().toLowerCase() == normalized) {
        return product;
      }
    }
    return null;
  }

  void _applyInvoiceProductDefaults(
    _CreateInvoiceItem item,
    String name, {
    bool preserveManualPrice = false,
  }) {
    item.nameCtrl.text = name;
    final match = _findProductByName(name);
    item.inventoryId = match?.id;
    if (match == null) return;

    final details = [
      match.category,
      match.storage,
      match.code,
    ].where((value) => value.trim().isNotEmpty).join(' • ');
    if (details.isNotEmpty) item.descriptionCtrl.text = details;
    if (match.colorName.isNotEmpty) item.colorCtrl.text = match.colorName;
    if (match.condition.isNotEmpty) item.conditionCtrl.text = match.condition;
    if (!preserveManualPrice && match.price > 0) {
      item.priceCtrl.text = match.price == match.price.roundToDouble()
          ? match.price.toInt().toString()
          : match.price.toString();
    }
  }

  void _applyCustomInvoiceProductName(_CreateInvoiceItem item, String name) {
    item.inventoryId = null;
    item.nameCtrl.text = name;
    item.descriptionCtrl.clear();
    item.colorCtrl.clear();
    item.conditionCtrl.clear();
  }

  void _applyInitialDraftIfNeeded() {
    final draft = widget.initialDraft;
    if (_didApplyInitialDraft || draft == null) return;
    _didApplyInitialDraft = true;

    final item = _createInvoiceItems.first;
    _applyInvoiceProductDefaults(
      item,
      draft.itemName,
      preserveManualPrice: draft.price != null,
    );
    if (draft.itemName.trim().isNotEmpty) {
      item.nameCtrl.text = draft.itemName.trim();
    }
    if (draft.description.trim().isNotEmpty) {
      item.descriptionCtrl.text = draft.description.trim();
    }
    if (draft.color.trim().isNotEmpty) {
      item.colorCtrl.text = draft.color.trim();
    }
    final condition = [
      draft.condition.trim(),
      draft.statusLabel.trim(),
    ].where((value) => value.isNotEmpty).toSet().join(' • ');
    if (condition.isNotEmpty) {
      item.conditionCtrl.text = condition;
    }
    if (draft.imeiSerial.trim().isNotEmpty) {
      item.imeiControllers.first.text = draft.imeiSerial.trim();
    }
    if (draft.price != null && draft.price! > 0) {
      item.priceCtrl.text = draft.price!.toStringAsFixed(
        draft.price! % 1 == 0 ? 0 : 2,
      );
    }
  }

  Future<void> _createInvoice() async {
    final hasExistingCustomer =
        _selectedCustomerId != null && _selectedCustomerId!.isNotEmpty;
    final hasManualCustomer = _firstNameCtrl.text.trim().isNotEmpty;

    if (!hasExistingCustomer && !hasManualCustomer) {
      showErrorSnackbar('Please choose a customer or fill in customer info.');
      return;
    }
    final validItems = _createInvoiceItems
        .where((item) => item.nameCtrl.text.trim().isNotEmpty)
        .toList();
    if (validItems.isEmpty) {
      showErrorSnackbar('Please add at least one item with a name.');
      return;
    }

    setState(() => _isSendingInvoice = true);
    try {
      var shopkeeperId = _profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await _profileCtrl.fetchProfile();
        shopkeeperId = _profileCtrl.userId;
      }

      final now = DateTime.now();
      final customerFirstName = _firstNameCtrl.text.trim();
      final customerLastName = _lastNameCtrl.text.trim();
      final customerName = [
        customerFirstName,
        customerLastName,
      ].where((value) => value.isNotEmpty).join(' ');
      final paymentType = _recordedPaymentMethod ?? 'Cash';
      final totalAmount = _totalAmount;

      final pdfItems = <InvoicePdfItem>[];
      for (final item in validItems) {
        final name = item.nameCtrl.text.trim();
        final code = [
          item.descriptionCtrl.text.trim(),
          item.colorCtrl.text.trim(),
          item.conditionCtrl.text.trim(),
        ].where((v) => v.isNotEmpty).join(' • ');
        final qty = int.tryParse(item.quantityCtrl.text.trim()) ?? 1;
        final unitPrice = double.tryParse(item.priceCtrl.text.trim()) ?? 0;
        final discount = double.tryParse(item.discountCtrl.text.trim()) ?? 0;
        final tax = double.tryParse(item.taxCtrl.text.trim()) ?? 0;
        final imeis = item.imeiControllers
            .map((c) => c.text.trim())
            .where((v) => v.isNotEmpty)
            .toList();

        if (imeis.isEmpty) {
          pdfItems.add(
            InvoicePdfItem(
              name: name,
              code: code,
              quantity: qty,
              unitPrice: unitPrice,
              discount: discount,
              tax: tax,
            ),
          );
        } else {
          for (final imei in imeis) {
            pdfItems.add(
              InvoicePdfItem(
                name: name,
                code: code,
                imeiSerial: imei,
                quantity: 1,
                unitPrice: unitPrice,
                discount: discount / imeis.length,
                tax: tax / imeis.length,
              ),
            );
          }
        }
      }

      final pdfFile = await InvoicePdfBuilder.build(
        fileNamePrefix: 'invoice',
        invoiceTitle: 'SALES INVOICE',
        invoiceNumber: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        shopName: _profileCtrl.shopName,
        shopAddress: _profileCtrl.shopAddress,
        shopEmail: _profileCtrl.email,
        shopPhone: _profileCtrl.whatsappNumber.isNotEmpty
            ? _profileCtrl.whatsappNumber
            : _profileCtrl.phone,
        customerName: customerName,
        customerEmail: _emailCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerAddress: _addressCtrl.text.trim(),
        paymentType: paymentType,
        currencySymbol: _profileCtrl.currencySymbol,
        amountPaid: _recordedAmountPaid,
        items: pdfItems,
        totalAmount: totalAmount,
        footerNote: 'Generated from iMoScan invoice flow.',
      );

      String customerId;
      if (hasExistingCustomer) {
        customerId = _selectedCustomerId!;
      } else {
        final createdCustomer = await _customerRepo.createCustomer(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
        );
        customerId = createdCustomer.id;
        if (customerId.isEmpty) {
          showErrorSnackbar('Failed to create customer');
          return;
        }
      }

      final payload = FormData();
      payload.fields.addAll([
        MapEntry('shopkeeperId', shopkeeperId),
        MapEntry('type', 'Custom invoice'),
        MapEntry('totalAmount', totalAmount.toString()),
        MapEntry('paymentMethod', paymentType),
        if (customerId.isNotEmpty) MapEntry('customerInfo', customerId),
        if (_recordedAmountPaid != null)
          MapEntry('amountPaid', _recordedAmountPaid!.toString()),
        if (_recordedAmountPaid != null)
          MapEntry(
            'dueAmount',
            (totalAmount - _recordedAmountPaid! < 0
                    ? 0
                    : totalAmount - _recordedAmountPaid!)
                .toString(),
          ),
      ]);

      for (final item in validItems) {
        if (item.inventoryId != null && item.inventoryId!.isNotEmpty) {
          payload.fields.add(MapEntry('itemsIds', item.inventoryId!));
        }
      }

      payload.files.add(
        MapEntry(
          'invoice',
          await MultipartFile.fromFile(
            pdfFile.path,
            filename: pdfFile.uri.pathSegments.last,
          ),
        ),
      );

      await _invoiceRepo.createInvoice(payload);
      if (!mounted) return;
      showSuccessSnackbar('Invoice created successfully!');
      _isViewInvoicesLoaded = false;
      _fetchViewInvoices();
      setState(() {
        _selectedCustomer = null;
        _selectedCustomerId = null;
        _recordedPaymentMethod = null;
        _recordedAmountPaid = null;
        _firstNameCtrl.clear();
        _lastNameCtrl.clear();
        _emailCtrl.clear();
        _phoneCtrl.clear();
        _addressCtrl.clear();
        for (final item in _createInvoiceItems) {
          item.dispose();
        }
        _createInvoiceItems.clear();
        _createInvoiceItems.add(_CreateInvoiceItem());
      });
    } on DioException catch (e) {
      if (!mounted) return;
      showErrorSnackbar(
        e.response?.data?['message'] ?? 'Failed to create invoice',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar('Failed to create invoice');
    } finally {
      if (mounted) setState(() => _isSendingInvoice = false);
    }
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
      _viewInvoices = await _invoiceRepo.getInvoices(shopkeeperId);
      _isViewInvoicesLoaded = true;
    } on DioException catch (e) {
      _viewInvoicesError =
          e.response?.data?['message'] ?? 'Failed to load invoices';
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

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Create Invoice'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildTabBar(),
          ),
          Expanded(
            child: _tabIndex == 3
                ? RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _fetchViewInvoices,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildViewInvoicesTab()],
                      ),
                    ),
                  )
                : SingleChildScrollView(
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
                        if (_tabIndex == 0 &&
                            !_isLoading &&
                            _errorMessage.isEmpty)
                          SizedBox(height: 100),
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
    final tabBg = isDark
        ? AppColors.cardBackground
        : Colors.white.withValues(alpha: 0.6);

    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: tabBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.fieldBorder
              : AppColors.primary.withValues(alpha: 0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.08),
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
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
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
                  color: isActive
                      ? AppColors.surfaceForeground
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  spec.label,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.surfaceForeground
                        : AppColors.textSecondary,
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
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        _buildCustomerDropdown(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(
                hint: 'First Name',
                controller: _firstNameCtrl,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InvoiceInputField(
                hint: 'Last Name',
                controller: _lastNameCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Email', controller: _emailCtrl),
        const SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer Phone Number',
          controller: _phoneCtrl,
        ),
        const SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer Billing Address',
          controller: _addressCtrl,
        ),
        const SizedBox(height: 14),
        ShopInfoCard(),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invoice Items',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add products and configure manual specifications',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: () =>
                  setState(() => _createInvoiceItems.add(_CreateInvoiceItem())),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16),
                  SizedBox(width: 4),
                  Text('Add Item', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...List.generate(
          _createInvoiceItems.length,
          (i) => _buildCreateInvoiceItemCard(i),
        ),
        const SizedBox(height: 16),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildCreateInvoiceItemCard(int index) {
    final item = _createInvoiceItems[index];
    final qty = int.tryParse(item.quantityCtrl.text.trim()) ?? 0;
    final price = double.tryParse(item.priceCtrl.text.trim()) ?? 0;
    final discount = double.tryParse(item.discountCtrl.text.trim()) ?? 0;
    final tax = double.tryParse(item.taxCtrl.text.trim()) ?? 0;
    final rawSubtotal = (qty * price) - discount + tax;
    final subTotal = rawSubtotal < 0 ? 0.0 : rawSubtotal;

    final isDark = AppColors.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackground
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.fieldBorder : const Color(0xFFE4E7EC),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF6BA0C8).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITEM #${index + 1}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_createInvoiceItems.length > 1) {
                    setState(() {
                      _createInvoiceItems[index].dispose();
                      _createInvoiceItems.removeAt(index);
                    });
                  } else {
                    setState(() {
                      _createInvoiceItems[index].inventoryId = null;
                      _createInvoiceItems[index].nameCtrl.clear();
                      _createInvoiceItems[index].descriptionCtrl.clear();
                      _createInvoiceItems[index].colorCtrl.clear();
                      _createInvoiceItems[index].conditionCtrl.clear();
                      _createInvoiceItems[index].quantityCtrl.text = '1';
                      _createInvoiceItems[index].priceCtrl.text = '0';
                      _createInvoiceItems[index].discountCtrl.clear();
                      _createInvoiceItems[index].taxCtrl.clear();
                      for (final c
                          in _createInvoiceItems[index].imeiControllers.sublist(
                            1,
                          )) {
                        c.dispose();
                      }
                      _createInvoiceItems[index].imeiControllers
                        ..removeRange(
                          1,
                          _createInvoiceItems[index].imeiControllers.length,
                        )
                        ..first.clear();
                    });
                  }
                },
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProductPickerField(
                  context,
                  selected: item.nameCtrl.text.trim().isEmpty
                      ? null
                      : item.nameCtrl.text.trim(),
                  hint: 'Item / Product Name *',
                  onSelect: (value) => setState(() {
                    final match = _findProductByName(value);
                    if (match != null) {
                      _applyInvoiceProductDefaults(
                        item,
                        match.name,
                        preserveManualPrice: false,
                      );
                    } else {
                      _applyCustomInvoiceProductName(item, value);
                    }
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InvoiceInputField(
            hint: 'Description / Storage / Details',
            controller: item.descriptionCtrl,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  context,
                  item.colorCtrl.text.trim().isEmpty
                      ? null
                      : item.colorCtrl.text.trim(),
                  'Color',
                  (value) => setState(() => item.colorCtrl.text = value),
                  _itemColorOptions,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  context,
                  item.conditionCtrl.text.trim().isEmpty
                      ? null
                      : item.conditionCtrl.text.trim(),
                  'Condition',
                  (value) => setState(() => item.conditionCtrl.text = value),
                  _itemConditionOptions,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStepperField(
                  hint: 'Quantity',
                  controller: item.quantityCtrl,
                  min: 1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStepperField(
                  hint: 'Price per Unit',
                  controller: item.priceCtrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStepperField(
                  hint: 'Discount (${_profileCtrl.currencySymbol})',
                  controller: item.discountCtrl,
                  min: 0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStepperField(
                  hint: 'Tax (${_profileCtrl.currencySymbol})',
                  controller: item.taxCtrl,
                  min: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IMEI / Serial Numbers',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => setState(
                  () => item.imeiControllers.add(TextEditingController()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(item.imeiControllers.length, (imeiIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InvoiceInputField(
                      hint: 'IMEI / Serial #${imeiIndex + 1}',
                      controller: item.imeiControllers[imeiIndex],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (item.imeiControllers.length > 1) {
                        item.imeiControllers[imeiIndex].dispose();
                        item.imeiControllers.removeAt(imeiIndex);
                      } else {
                        item.imeiControllers[imeiIndex].clear();
                      }
                    }),
                    child: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Calculation Sub Total',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_profileCtrl.currencySymbol}${subTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              onPressed: _sessionExpired
                  ? () async {
                      await Get.find<AuthController>().logout();
                      Get.offAll(() => const LoginScreenView());
                    }
                  : _loadInvoiceData,
              child: Text(_sessionExpired ? 'Log in again' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDropdown() {
    return InvoiceCustomerPicker(
      customers: _customers,
      selected: _selectedCustomer,
      isOpen: _isCustomerDropdownOpen,
      isLoading: _isCustomersLoading,
      searchController: _customerSearchCtrl,
      dropdownLoaderSize: _dropdownLoaderSize,
      onToggle: () {
        if (_isCustomerDropdownOpen) {
          _customerSearchCtrl.clear();
          setState(() => _isCustomerDropdownOpen = false);
        } else {
          _openCustomerPicker();
        }
      },
      onSearchChanged: (_) => setState(() {}),
      onAddCustomer: () =>
          _addCustomerFromPicker(_customerSearchCtrl, _selectCustomer),
      onSelect: _selectCustomer,
    );
  }

  Widget _buildStepperField({
    required String hint,
    required TextEditingController controller,
    double step = 1,
    double min = 0,
  }) {
    void adjust(double delta) {
      final current = double.tryParse(controller.text.trim()) ?? 0;
      var next = current + delta;
      if (next < min) next = min;
      setState(
        () => controller.text = next == next.roundToDouble()
            ? next.toInt().toString()
            : next.toString(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: AppColors.isDark ? 0.6 : 0.72,
          ),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                isDense: true,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => adjust(step),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 6),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              InkWell(
                onTap: () => adjust(-step),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 6),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
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
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: AppColors.primary.withValues(
              alpha: AppColors.isDark ? 0.6 : 0.72,
            ),
            width: 1.2,
          ),
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

  Widget _buildProductPickerField(
    BuildContext context, {
    required String? selected,
    required String hint,
    required void Function(String) onSelect,
  }) {
    return _buildDropdown(
      context,
      selected,
      hint,
      onSelect,
      const [],
      onTap: () => _showProductSelectionSheet(
        context,
        title: hint,
        selected: selected,
        onSelect: onSelect,
      ),
    );
  }

  Color? _selectionAccentColor(String title, String item) {
    if (title.trim().toLowerCase() != 'color') return null;

    switch (item.trim().toLowerCase()) {
      case 'black':
        return const Color(0xFF111827);
      case 'midnight':
        return const Color(0xFF1E293B);
      case 'white':
        return Colors.white;
      case 'starlight':
        return const Color(0xFFF5E7C4);
      case 'natural titanium':
        return const Color(0xFF9A8F7A);
      case 'rose gold':
        return const Color(0xFFB76E79);
      case 'blue':
        return const Color(0xFF3B82F6);
      case 'sky blue':
        return const Color(0xFF60A5FA);
      case 'silver':
        return const Color(0xFFD1D5DB);
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'green':
        return const Color(0xFF10B981);
      case 'teal':
        return const Color(0xFF14B8A6);
      case 'purple':
        return const Color(0xFF8B5CF6);
      case 'pink':
        return const Color(0xFFEC4899);
      case 'red':
        return const Color(0xFFEF4444);
      case 'orange':
        return const Color(0xFFF97316);
      case 'yellow':
        return const Color(0xFFEAB308);
      case 'brown':
        return const Color(0xFF8B5E3C);
      case 'beige':
        return const Color(0xFFD6C2A1);
      case 'gray':
      case 'grey':
        return const Color(0xFF9CA3AF);
      default:
        return null;
    }
  }

  Widget _buildSelectionTile(
    BuildContext context, {
    required String title,
    required String item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final accentColor = _selectionAccentColor(title, item);
    // Pale swatches (white, silver, starlight) need a neutral ring or they
    // vanish into the row.
    final needsLightRing =
        accentColor != null && accentColor.computeLuminance() > 0.75;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            // Flat neutral row. The swatch carries the colour; washing the
            // whole row in it left every option looking faded.
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              if (accentColor != null) ...[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    // The real colour, flat, so it reads truthfully.
                    color: accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: needsLightRing
                          ? AppColors.fieldBorder
                          : Colors.black.withValues(alpha: 0.14),
                      width: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.fieldBorder,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.surfaceForeground,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelectionTile(
    BuildContext context, {
    required InvoiceProduct product,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final subtitle = _productPickerSubtitle(product);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.42)
                  : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.fieldBorder,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.surfaceForeground,
                        size: 15,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Always-visible "add a new item" row. With nothing typed it invites a
  /// name and focuses the field; once a name is typed it commits it.
  Widget _buildCustomProductTile(
    BuildContext context, {
    required String value,
    required VoidCallback onTap,
  }) {
    final hasValue = value.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasValue ? 'Use "$value"' : 'Add a new item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      hasValue
                          ? 'Not in your inventory - add it as a new item'
                          : 'Tap to name an item you do not stock',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
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

  Future<void> _showProductSelectionSheet(
    BuildContext context, {
    required String title,
    required String? selected,
    required void Function(String) onSelect,
  }) async {
    final searchCtrl = TextEditingController(text: selected ?? '');
    final searchFocus = FocusNode();

    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.76;
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchCtrl.text.trim();
            final results = _searchableProducts(query);
            final normalizedQuery = query.toLowerCase();
            final hasExactMatch = results.any(
              (product) => product.name.trim().toLowerCase() == normalizedQuery,
            );

            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.fieldBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search existing items or use a new name.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.fieldBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.fieldBorder),
                        ),
                        child: TextField(
                          controller: searchCtrl,
                          focusNode: searchFocus,
                          onChanged: (_) => setSheetState(() {}),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search item name, category, storage...',
                            hintStyle: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      searchCtrl.clear();
                                      setSheetState(() {});
                                    },
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                      size: 18,
                                    ),
                                  ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (!hasExactMatch) ...[
                        _buildCustomProductTile(
                          sheetContext,
                          value: query,
                          onTap: () async {
                            if (query.isNotEmpty) {
                              Navigator.pop(sheetContext, query);
                              return;
                            }
                            // Nothing typed yet: ask for the name outright
                            // rather than silently moving the cursor.
                            final name = await showNewItemNameDialog(
                              sheetContext,
                            );
                            if (name == null || !sheetContext.mounted) return;
                            Navigator.pop(sheetContext, name);
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (results.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              query.isEmpty
                                  ? 'No items found yet'
                                  : 'No matching items found',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        )
                      else
                        Flexible(
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: results.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) {
                              final product = results[index];
                              return _buildProductSelectionTile(
                                sheetContext,
                                product: product,
                                isSelected:
                                    selected?.trim().toLowerCase() ==
                                    product.name.trim().toLowerCase(),
                                onTap: () =>
                                    Navigator.pop(sheetContext, product.name),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // The sheet is still animating out, so the field would read a disposed
    // controller. Tear both down once the route is gone.
    Future.delayed(const Duration(milliseconds: 400), () {
      searchCtrl.dispose();
      searchFocus.dispose();
    });

    if (choice != null) {
      onSelect(choice);
    }
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
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.72;
        final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items.isEmpty
                        ? 'Nothing available to choose right now.'
                        : 'Select one option from the list below.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (items.isEmpty)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                color: AppColors.textSecondary,
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Nothing to choose from yet',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Options will show up here once available.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) {
                          final item = items[index];
                          return _buildSelectionTile(
                            sheetContext,
                            title: title,
                            item: item,
                            isSelected: selected == item,
                            onTap: () => Navigator.pop(sheetContext, item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (choice != null) {
      onSelect(choice);
    }
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
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Identity validation framework controls',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        SizedBox(height: 14),
        InvoiceCustomerPicker(
          customers: _customers,
          selected: _selectedPurchaseCustomer,
          isOpen: _isPurchaseCustomerDropdownOpen,
          isLoading: _isCustomersLoading,
          searchController: _purchaseCustomerSearchCtrl,
          dropdownLoaderSize: _dropdownLoaderSize,
          onToggle: () {
            if (_isPurchaseCustomerDropdownOpen) {
              _purchaseCustomerSearchCtrl.clear();
              setState(() => _isPurchaseCustomerDropdownOpen = false);
            } else {
              _openPurchaseCustomerPicker();
            }
          },
          onSearchChanged: (_) => setState(() {}),
          onAddCustomer: () => _addCustomerFromPicker(
            _purchaseCustomerSearchCtrl,
            _selectPurchaseCustomer,
          ),
          onSelect: _selectPurchaseCustomer,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(
                hint: 'First Name',
                controller: _pFirstNameCtrl,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InvoiceInputField(
                hint: 'Last Name',
                controller: _pLastNameCtrl,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Email', controller: _pEmailCtrl),
        SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer Phone Number',
          controller: _pPhoneCtrl,
        ),
        SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer Billing Address',
          controller: _pAddressCtrl,
        ),
        SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer ID Number',
          controller: _pIdNumberCtrl,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(
                hint: 'Customer Name',
                controller: _pCustomerNameCtrl,
              ),
            ),
            SizedBox(width: 10),
            OutlinedButton(
              onPressed: _isExtractingNid ? null : _showCaptureNidSheet,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: _isExtractingNid
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
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
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure specifications and accumulate tracking logs',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            OutlinedButton(
              onPressed: () =>
                  setState(() => _purchaseItems.add(_PurchaseItem())),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('Add Item', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(
            () => _purchaseAddToInventory = !_purchaseAddToInventory,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _purchaseAddToInventory,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) =>
                      setState(() => _purchaseAddToInventory = value),
                ),
              ),
              Text(
                'Add to inventory',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (_purchaseAddToInventory) ...[
          SizedBox(height: 10),
          Text(
            'Category Name',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          _buildDropdown(
            context,
            _purchaseCategory,
            'Select category',
            (value) => setState(() => _purchaseCategory = value),
            _purchaseCategoryOptions,
          ),
        ],
        SizedBox(height: 14),
        ...List.generate(
          _purchaseItems.length,
          (i) => _buildPurchaseItemCard(i),
        ),
        SizedBox(height: 20),
        _buildRecordPaymentCard(),
        SizedBox(height: 100),
      ],
    );
  }

  Widget _buildRecordPaymentCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'RECORD PAYMENT',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Select how you would like to receive payment.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          SizedBox(height: 14),
          _buildPaymentMethodPreviewRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Pay from Available Cash',
            subtitle: 'Deduct from available cash balance',
          ),
          SizedBox(height: 10),
          _buildPaymentMethodPreviewRow(
            icon: Icons.account_balance_outlined,
            title: 'Bank Transfer',
            subtitle: 'Customer will transfer to your account',
          ),
          SizedBox(height: 16),
          AppButton(
            label: _isSendingPurchase
                ? 'Please wait...'
                : 'Continue to Payment',
            onPressed: _isSendingPurchase
                ? null
                : () {
                    if (!_validatePurchaseForm()) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecordPaymentPage(
                          invoiceTotal: _purchaseGrandTotal,
                          availableCash: _availableCash,
                          onSubmitPayment: _createPurchaseInvoice,
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodPreviewRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.radio_button_unchecked,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItemCard(int index) =>
      _buildItemCard(_purchaseItems, index);

  void _applyProductDefaults(_PurchaseItem item, String name) {
    item.nameCtrl.text = name;
    InvoiceProduct? match;
    for (final product in _products) {
      if (product.name == name) {
        match = product;
        break;
      }
    }
    if (match == null) return;
    if (match.storage.isNotEmpty) item.storageCtrl.text = match.storage;
    if (match.colorName.isNotEmpty) item.colorCtrl.text = match.colorName;
    if (match.condition.isNotEmpty) item.conditionCtrl.text = match.condition;
    if (match.price > 0) {
      item.priceCtrl.text = match.price == match.price.roundToDouble()
          ? match.price.toInt().toString()
          : match.price.toString();
    }
  }

  void _applyCustomProductName(_PurchaseItem item, String name) {
    item.nameCtrl.text = name;
    item.storageCtrl.clear();
    item.colorCtrl.clear();
    item.conditionCtrl.clear();
  }

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
        color: isDark
            ? AppColors.cardBackground
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.fieldBorder : const Color(0xFFE4E7EC),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF6BA0C8).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEVICE #${index + 1}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
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
                      for (final c in items[index].imeiControllers.sublist(1)) {
                        c.dispose();
                      }
                      items[index].imeiControllers
                        ..removeRange(1, items[index].imeiControllers.length)
                        ..first.clear();
                    });
                  }
                },
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildProductPickerField(
            context,
            selected: item.nameCtrl.text.trim().isEmpty
                ? null
                : item.nameCtrl.text.trim(),
            hint: 'Item Name*',
            onSelect: (value) => setState(() {
              final match = _findProductByName(value);
              if (match != null) {
                _applyProductDefaults(item, match.name);
              } else {
                _applyCustomProductName(item, value);
              }
            }),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  context,
                  item.storageCtrl.text.isEmpty ? null : item.storageCtrl.text,
                  'Storage',
                  (value) => setState(() => item.storageCtrl.text = value),
                  _itemStorageOptions,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildDropdown(
                  context,
                  item.colorCtrl.text.isEmpty ? null : item.colorCtrl.text,
                  'Color',
                  (value) => setState(() => item.colorCtrl.text = value),
                  _itemColorOptions,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  context,
                  item.conditionCtrl.text.trim().isEmpty
                      ? null
                      : item.conditionCtrl.text.trim(),
                  'Condition',
                  (value) => setState(() => item.conditionCtrl.text = value),
                  _itemConditionOptions,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildStepperField(
                  hint: 'Quantity',
                  controller: item.quantityCtrl,
                  min: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildStepperField(
            hint: 'Price per Unit',
            controller: item.priceCtrl,
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'IMEI / Serial Numbers',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () => setState(
                  () => item.imeiControllers.add(TextEditingController()),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          ...List.generate(item.imeiControllers.length, (imeiIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InvoiceInputField(
                      hint: 'IMEI / Serial #${imeiIndex + 1}',
                      controller: item.imeiControllers[imeiIndex],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      if (item.imeiControllers.length > 1) {
                        item.imeiControllers[imeiIndex].dispose();
                        item.imeiControllers.removeAt(imeiIndex);
                      } else {
                        item.imeiControllers[imeiIndex].clear();
                      }
                    }),
                    child: Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: 6),
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
                Text(
                  'Item Calculation Sub Total',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_profileCtrl.currencySymbol}${subTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    Text(
                      'Capture NID',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add a photo of the front (required) and back (optional) of the NID card.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildNidImageTile(
                      label: 'Front of NID',
                      required: true,
                      image: frontImage,
                      onTap: () async {
                        final picked = await _pickNidImage();
                        if (picked != null) {
                          setSheetState(() => frontImage = picked);
                        }
                      },
                      onClear: frontImage == null
                          ? null
                          : () => setSheetState(() => frontImage = null),
                    ),
                    const SizedBox(height: 10),
                    _buildNidImageTile(
                      label: 'Back of NID (optional)',
                      required: false,
                      image: backImage,
                      onTap: () async {
                        final picked = await _pickNidImage();
                        if (picked != null) {
                          setSheetState(() => backImage = picked);
                        }
                      },
                      onClear: backImage == null
                          ? null
                          : () => setSheetState(() => backImage = null),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Extract NID',
                      onPressed: frontImage == null && backImage == null
                          ? null
                          : () => Navigator.pop(sheetCtx, true),
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
                child: Image.file(
                  image,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.badge_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                image != null ? 'Selected' : label,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.dangerColor,
                  size: 18,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<File?> _pickNidImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  Future<void> _extractNid() async {
    if (_nidFrontImage == null && _nidBackImage == null) return;

    setState(() => _isExtractingNid = true);
    try {
      final nidNumber = await _invoiceRepo.extractNid(
        frontImage: _nidFrontImage,
        backImage: _nidBackImage,
      );
      _pIdNumberCtrl.text = nidNumber;
      showSuccessSnackbar('NID number extracted successfully.');
    } on InvoiceException catch (e) {
      showErrorSnackbar(e.message);
    } catch (_) {
      showErrorSnackbar('Failed to extract NID from image.');
    } finally {
      if (mounted) setState(() => _isExtractingNid = false);
    }
  }

  bool _validatePurchaseForm() {
    if (_pFirstNameCtrl.text.trim().isEmpty) {
      showErrorSnackbar('Please enter customer first name');
      return false;
    }
    final hasItems = _purchaseItems.any(
      (item) => item.nameCtrl.text.trim().isNotEmpty,
    );
    if (!hasItems) {
      showErrorSnackbar('Please add at least one item');
      return false;
    }
    return true;
  }

  Future<File?> _createPurchaseInvoice({String paymentMethod = 'cash'}) async {
    if (!_validatePurchaseForm()) return null;
    final grandTotal = _purchaseGrandTotal;

    setState(() => _isSendingPurchase = true);
    try {
      var shopkeeperId = _profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await _profileCtrl.fetchProfile();
        shopkeeperId = _profileCtrl.userId;
      }

      final now = DateTime.now();
      final customerName = [
        _pFirstNameCtrl.text.trim(),
        _pLastNameCtrl.text.trim(),
      ].where((v) => v.isNotEmpty).join(' ');

      final pdfItems = <InvoicePdfItem>[];
      for (final item in _purchaseItems) {
        final name = item.nameCtrl.text.trim();
        if (name.isEmpty) continue;

        final code = [
          item.storageCtrl.text.trim(),
          item.colorCtrl.text.trim(),
          item.conditionCtrl.text.trim(),
        ].where((v) => v.isNotEmpty).join(' / ');
        final unitPrice = double.tryParse(item.priceCtrl.text.trim()) ?? 0;
        final imeis = item.imeiControllers
            .map((c) => c.text.trim())
            .where((v) => v.isNotEmpty)
            .toList();

        if (imeis.isEmpty) {
          pdfItems.add(
            InvoicePdfItem(
              name: name,
              code: code,
              quantity: int.tryParse(item.quantityCtrl.text.trim()) ?? 1,
              unitPrice: unitPrice,
            ),
          );
        } else {
          for (final imei in imeis) {
            pdfItems.add(
              InvoicePdfItem(
                name: name,
                code: code,
                imeiSerial: imei,
                quantity: 1,
                unitPrice: unitPrice,
              ),
            );
          }
        }
      }

      final pdfFile = await InvoicePdfBuilder.buildPurchaseReceipt(
        fileNamePrefix: 'purchase_receipt',
        invoiceNumber: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        shopName: _profileCtrl.shopName,
        shopAddress: _profileCtrl.shopAddress,
        shopPhone: _profileCtrl.whatsappNumber.isNotEmpty
            ? _profileCtrl.whatsappNumber
            : _profileCtrl.phone,
        customerName: customerName,
        customerPhone: _pPhoneCtrl.text.trim(),
        customerIdNumber: _pIdNumberCtrl.text.trim(),
        items: pdfItems,
        totalAmount: grandTotal,
        currencySymbol: _profileCtrl.currencySymbol,
      );

      final payload = FormData();
      payload.fields.addAll([
        MapEntry('shopkeeperId', shopkeeperId),
        MapEntry('type', 'purchase'),
        MapEntry('totalAmount', grandTotal.toString()),
        MapEntry('paymentMethod', paymentMethod),
      ]);
      payload.files.add(
        MapEntry(
          'invoice',
          await MultipartFile.fromFile(
            pdfFile.path,
            filename: pdfFile.uri.pathSegments.last,
          ),
        ),
      );

      await _invoiceRepo.createInvoice(payload);
      if (!mounted) return null;
      showSuccessSnackbar('Purchase receipt created successfully!');
      _isViewInvoicesLoaded = false;
      _fetchViewInvoices();
      setState(() {
        _selectedPurchaseCustomer = null;
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
      return pdfFile;
    } on DioException catch (e) {
      if (!mounted) return null;
      showErrorSnackbar(
        e.response?.data?['message'] ?? 'Failed to create purchase receipt',
      );
      return null;
    } catch (e) {
      if (!mounted) return null;
      showErrorSnackbar('Failed to create purchase receipt');
      return null;
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
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 14),
        InvoiceCustomerPicker(
          customers: _customers,
          selected: _selectedDeliveryCustomer,
          isOpen: _isDeliveryCustomerDropdownOpen,
          isLoading: _isCustomersLoading,
          searchController: _deliveryCustomerSearchCtrl,
          dropdownLoaderSize: _dropdownLoaderSize,
          onToggle: () {
            if (_isDeliveryCustomerDropdownOpen) {
              _deliveryCustomerSearchCtrl.clear();
              setState(() => _isDeliveryCustomerDropdownOpen = false);
            } else {
              _openDeliveryCustomerPicker();
            }
          },
          onSearchChanged: (_) => setState(() {}),
          onAddCustomer: () => _addCustomerFromPicker(
            _deliveryCustomerSearchCtrl,
            _selectDeliveryCustomer,
          ),
          onSelect: _selectDeliveryCustomer,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InvoiceInputField(
                hint: 'First Name',
                controller: _dFirstNameCtrl,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: InvoiceInputField(
                hint: 'Last Name',
                controller: _dLastNameCtrl,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        InvoiceInputField(hint: 'Customer Email', controller: _dEmailCtrl),
        SizedBox(height: 10),
        InvoiceInputField(
          hint: 'Customer Phone Number',
          controller: _dPhoneCtrl,
        ),
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
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton(
              onPressed: () =>
                  setState(() => _deliveryItems.add(_PurchaseItem())),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('Add Item', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        SizedBox(height: 14),
        ...List.generate(
          _deliveryItems.length,
          (i) => _buildItemCard(_deliveryItems, i),
        ),
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
    final hasItems = _deliveryItems.any(
      (item) => item.nameCtrl.text.trim().isNotEmpty,
    );
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
      final customerName = [
        _dFirstNameCtrl.text.trim(),
        _dLastNameCtrl.text.trim(),
      ].where((v) => v.isNotEmpty).join(' ');

      final pdfItems = <InvoicePdfItem>[];
      for (final item in _deliveryItems) {
        final name = item.nameCtrl.text.trim();
        if (name.isEmpty) continue;

        final code = [
          item.storageCtrl.text.trim(),
          item.colorCtrl.text.trim(),
          item.conditionCtrl.text.trim(),
        ].where((v) => v.isNotEmpty).join(' / ');
        final unitPrice = double.tryParse(item.priceCtrl.text.trim()) ?? 0;
        final imeis = item.imeiControllers
            .map((c) => c.text.trim())
            .where((v) => v.isNotEmpty)
            .toList();

        if (imeis.isEmpty) {
          pdfItems.add(
            InvoicePdfItem(
              name: name,
              code: code,
              quantity: int.tryParse(item.quantityCtrl.text.trim()) ?? 1,
              unitPrice: unitPrice,
            ),
          );
        } else {
          for (final imei in imeis) {
            pdfItems.add(
              InvoicePdfItem(
                name: name,
                code: code,
                imeiSerial: imei,
                quantity: 1,
                unitPrice: unitPrice,
              ),
            );
          }
        }
      }

      final pdfFile = await InvoicePdfBuilder.build(
        fileNamePrefix: 'delivery_invoice',
        invoiceTitle: 'DELIVERY INVOICE',
        invoiceNumber: now.millisecondsSinceEpoch.toString(),
        createdAt: now,
        shopName: _profileCtrl.shopName,
        shopAddress: _profileCtrl.shopAddress,
        shopEmail: _profileCtrl.email,
        shopPhone: _profileCtrl.whatsappNumber.isNotEmpty
            ? _profileCtrl.whatsappNumber
            : _profileCtrl.phone,
        customerName: customerName,
        customerEmail: _dEmailCtrl.text.trim(),
        customerPhone: _dPhoneCtrl.text.trim(),
        customerAddress: _dAddressCtrl.text.trim(),
        paymentType: 'cash',
        currencySymbol: _profileCtrl.currencySymbol,
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
      payload.files.add(
        MapEntry(
          'invoice',
          await MultipartFile.fromFile(
            pdfFile.path,
            filename: pdfFile.uri.pathSegments.last,
          ),
        ),
      );

      await _invoiceRepo.createInvoice(payload);
      if (!mounted) return;
      showSuccessSnackbar('Delivery invoice created successfully!');
      _isViewInvoicesLoaded = false;
      _fetchViewInvoices();
      setState(() {
        _selectedDeliveryCustomer = null;
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
      showErrorSnackbar(
        e.response?.data?['message'] ?? 'Failed to create delivery invoice',
      );
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
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: AppColors.primary,
          ),
        ),
      );
    }
    if (_viewInvoicesError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            children: [
              Text(
                _viewInvoicesError,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _fetchViewInvoices,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_viewInvoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Text(
            'No invoices yet',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
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
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${_viewInvoices.length} total',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        SizedBox(height: 14),
        ..._viewInvoices.map((inv) {
          final type = inv.type;
          final amount = inv.totalAmount;
          final date = _formatInvoiceDate(inv.createdAt);
          final customer = inv.customerName;
          final pdfUrl = inv.pdfUrl;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (pdfUrl != null) {
                  showDialog(
                    context: context,
                    useSafeArea: false,
                    builder: (_) => _PdfViewerPage(
                      url: pdfUrl,
                      title:
                          '${type[0].toUpperCase()}${type.substring(1)} Invoice',
                    ),
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
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${type[0].toUpperCase()}${type.substring(1)} Invoice',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            customer,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (amount != null)
                          Text(
                            '${_profileCtrl.currencySymbol}${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
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

  Widget _buildRecordPaymentRow() {
    final method = _recordedPaymentMethod;
    final paid = _recordedAmountPaid;
    final hasRecord = method != null || paid != null;
    final due = hasRecord ? (_totalAmount - (paid ?? 0)) : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _showRecordPaymentSheet,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Icon(
              hasRecord ? Icons.check_circle : Icons.payments_outlined,
              color: hasRecord ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: hasRecord
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${method ?? 'Cash'} · Paid ${_profileCtrl.currencySymbol}${(paid ?? 0).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Balance due ${_profileCtrl.currencySymbol}${due!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Record Payment',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            Icon(
              hasRecord ? Icons.edit_outlined : Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecordPaymentSheet() async {
    var method = _recordedPaymentMethod ?? paymentTypes.first;
    final amountCtrl = TextEditingController(
      text: _recordedAmountPaid != null
          ? _recordedAmountPaid!.toStringAsFixed(2)
          : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Record Payment',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  _buildDropdown(
                    sheetContext,
                    method,
                    'Payment Method',
                    (value) => setSheetState(() => method = value),
                    paymentTypes,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Amount Paid',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  InvoiceInputField(
                    hint: '0.00',
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 14),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: amountCtrl,
                    builder: (context, value, _) {
                      final paid = double.tryParse(value.text.trim()) ?? 0;
                      final due = _totalAmount - paid;
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.fieldBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.fieldBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Balance Due',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${_profileCtrl.currencySymbol}${due.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 20),
                  AppButton(
                    label: 'Save',
                    onPressed: () {
                      setState(() {
                        _recordedPaymentMethod = method;
                        _recordedAmountPaid = double.tryParse(
                          amountCtrl.text.trim(),
                        );
                      });
                      Navigator.pop(sheetContext);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${_profileCtrl.currencySymbol}${_totalAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
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
          _buildRecordPaymentRow(),
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
    final viewerUrl =
        'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(widget.url)}';
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
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
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

class _CreateInvoiceItem {
  String? inventoryId;
  final nameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  final conditionCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController(text: '0');
  final discountCtrl = TextEditingController(text: '');
  final taxCtrl = TextEditingController(text: '');
  final List<TextEditingController> imeiControllers = [TextEditingController()];

  void dispose() {
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    colorCtrl.dispose();
    conditionCtrl.dispose();
    quantityCtrl.dispose();
    priceCtrl.dispose();
    discountCtrl.dispose();
    taxCtrl.dispose();
    for (final c in imeiControllers) {
      c.dispose();
    }
  }
}

class _PurchaseItem {
  final nameCtrl = TextEditingController();
  final storageCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  final conditionCtrl = TextEditingController();
  final quantityCtrl = TextEditingController(text: '1');
  final priceCtrl = TextEditingController(text: '0');
  final List<TextEditingController> imeiControllers = [TextEditingController()];

  void dispose() {
    nameCtrl.dispose();
    storageCtrl.dispose();
    colorCtrl.dispose();
    conditionCtrl.dispose();
    quantityCtrl.dispose();
    priceCtrl.dispose();
    for (final c in imeiControllers) {
      c.dispose();
    }
  }
}
