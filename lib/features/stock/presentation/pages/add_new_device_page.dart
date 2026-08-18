import 'dart:io';

import 'package:dio/dio.dart' show DioException;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app_ground_view.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/controller/home_controller.dart';
import '../../data/repositories/inventory_repository_impl.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../controller/stock_controller.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';

class AddNewDevicePage extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;
  final InventoryItem? initialItem;

  const AddNewDevicePage({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
    this.initialItem,
  });

  @override
  State<AddNewDevicePage> createState() => _AddNewDevicePageState();
}

class _AddNewDevicePageState extends State<AddNewDevicePage> {
  late final InventoryRepository _inventoryRepo;
  late final StockController _stockCtrl;

  final _itemNameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _imeiCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController(text: '0.00');
  final _expectedPriceCtrl = TextEditingController(text: '0.00');
  final _quantityCtrl = TextEditingController(text: '1');
  final _minStockCtrl = TextEditingController(text: '0');
  final _groupKeyCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();

  int _selectedTab = 0;
  bool _isSaving = false;
  String? _selectedCategoryId;
  String? _selectedBrand;
  String? _selectedColor;
  String? _selectedStorage;
  String _selectedCondition = 'good condition';
  String? _imagePath;
  String? _existingImageUrl;
  PlatformFile? _csvFile;
  final List<_BulkDeviceRowForm> _bulkRows = [];

  static const _tabs = ['Add Item', 'Bulk Upload', 'Import CSV'];
  static const _brands = [
    'Apple',
    'Samsung',
    'Xiaomi',
    'Oppo',
    'Vivo',
    'Realme',
    'Google',
    'OnePlus',
    'Huawei',
    'Nokia',
  ];
  static const _colors = [
    'Black',
    'White',
    'Blue',
    'Silver',
    'Gold',
    'Green',
    'Purple',
    'Gray',
  ];
  static const _storages = ['32GB', '64GB', '128GB', '256GB', '512GB', '1TB'];
  static const _conditions = {'New': 'new', 'Good Condition': 'good condition'};
  bool get _isEditing => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    _inventoryRepo = InventoryRepositoryImpl(ApiClient(baseUrl));
    _stockCtrl = Get.find<StockController>();
    _selectedCategoryId = widget.initialCategoryId;
    _bulkRows.add(_BulkDeviceRowForm());
    _prefillFromInitialItem();
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeCategories());
  }

  void _prefillFromInitialItem() {
    final item = widget.initialItem;
    if (item == null) return;

    _itemNameCtrl.text = item.itemName;
    _skuCtrl.text = item.sku ?? '';
    _modelCtrl.text = item.modelNumber ?? '';
    _imeiCtrl.text = item.imeiNumber;
    _purchasePriceCtrl.text = _displayNumber(
      item.purchasePrice,
      fallback: '0.00',
    );
    _expectedPriceCtrl.text = _displayNumber(
      item.expectedPrice,
      fallback: '0.00',
    );
    _quantityCtrl.text = _displayNumber(item.quantity, fallback: '1');
    _minStockCtrl.text = _displayNumber(item.minStockLevel, fallback: '0');
    _groupKeyCtrl.text = item.groupKey ?? '';
    _detailsCtrl.text = item.productDetails ?? '';

    _selectedCategoryId = item.categoryId ?? _selectedCategoryId;
    _selectedBrand = _resolveSelectableValue(_brands, item.brand);
    _selectedColor = _resolveSelectableValue(_colors, item.color);
    _selectedStorage = _resolveSelectableValue(_storages, item.storage);

    final currentState = item.currentState;
    if (_conditions.containsValue(currentState)) {
      _selectedCondition = currentState;
    }

    _existingImageUrl = item.imageUrl;
  }

  Future<void> _primeCategories() async {
    if (_stockCtrl.categories.isNotEmpty) return;
    await _stockCtrl.fetchCategories();
    if (mounted) setState(() {});
  }

  Future<void> _openScanner(TextEditingController target) async {
    final scannedValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (!mounted || scannedValue == null || scannedValue.trim().isEmpty) return;
    target.text = scannedValue.trim();
    setState(() {});
  }

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _skuCtrl.dispose();
    _modelCtrl.dispose();
    _imeiCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _expectedPriceCtrl.dispose();
    _quantityCtrl.dispose();
    _minStockCtrl.dispose();
    _groupKeyCtrl.dispose();
    _detailsCtrl.dispose();
    for (final row in _bulkRows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final bytes = await file.length();
    if (bytes > 5 * 1024 * 1024) {
      showErrorSnackbar('Please choose an image smaller than 5MB');
      return;
    }

    if (!mounted) return;
    setState(() => _imagePath = picked.path);
  }

  Future<void> _pickBulkRowImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _bulkRows[index].imagePath = picked.path);
  }

  void _addBulkRow() {
    setState(() => _bulkRows.add(_BulkDeviceRowForm()));
  }

  void _removeBulkRow(int index) {
    if (_bulkRows.length == 1) return;
    setState(() {
      final row = _bulkRows.removeAt(index);
      row.dispose();
    });
  }

  Future<void> _pickCsvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xls', 'xlsx'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.size > 5 * 1024 * 1024) {
      showErrorSnackbar('Please choose a file smaller than 5MB');
      return;
    }

    final extension = file.extension?.toLowerCase();
    if (extension == null || !['csv', 'xls', 'xlsx'].contains(extension)) {
      showErrorSnackbar('Only CSV, XLS or XLSX files are supported');
      return;
    }

    if (!mounted) return;
    setState(() => _csvFile = file);
  }

  void _removeCsvFile() {
    setState(() => _csvFile = null);
  }

  Future<void> _submit() async {
    final itemName = _itemNameCtrl.text.trim();
    final imei = _imeiCtrl.text.trim();
    if (itemName.isEmpty) {
      showErrorSnackbar('Product name is required');
      return;
    }
    if (imei.isEmpty) {
      showErrorSnackbar('IMEI / Serial Number is required');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'itemName': itemName,
        'imeiNumber': imei,
        'sku': _nullableText(_skuCtrl),
        'brand': _selectedBrand,
        'color': _selectedColor,
        'storage': _selectedStorage,
        'modelNumber': _nullableText(_modelCtrl),
        'purchasePrice': _parseNumber(_purchasePriceCtrl.text),
        'expectedPrice': _parseNumber(_expectedPriceCtrl.text),
        'quantity': _parseInt(_quantityCtrl.text),
        'minStockLevel': _parseInt(_minStockCtrl.text),
        'groupKey': _nullableText(_groupKeyCtrl),
        'currentState': _selectedCondition,
        'productDetails': _nullableText(_detailsCtrl),
        'categoryId': _selectedCategoryId,
      }..removeWhere((_, value) => value == null);

      if (_isEditing) {
        final itemId = widget.initialItem?.id;
        if (itemId == null || itemId.isEmpty) {
          throw Exception('Missing inventory item id');
        }

        await _inventoryRepo.updateItem(
          id: itemId,
          data: data,
          imagePath: _imagePath,
        );
      } else {
        await _inventoryRepo.createItem(data: data, imagePath: _imagePath);
      }
      await _stockCtrl.fetchCategories();
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().fetchAllData();
      }
      if (!mounted) return;
      showSuccessSnackbar(
        _isEditing
            ? 'Device updated successfully'
            : 'Device added to inventory',
      );
      Navigator.pop(context, true);
    } on DioException catch (e) {
      showErrorSnackbar(
        e.response?.data?['message'] ??
            (_isEditing
                ? 'Failed to update device'
                : 'Failed to add device to inventory'),
      );
    } catch (_) {
      showErrorSnackbar(
        _isEditing
            ? 'Failed to update device'
            : 'Failed to add device to inventory',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitBulk() async {
    final validRows = _bulkRows
        .where((row) => row.barcodeCtrl.text.trim().isNotEmpty)
        .toList();

    if (validRows.isEmpty) {
      showErrorSnackbar('At least one barcode is required');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final items = <Map<String, dynamic>>[];
      for (final row in validRows) {
        final quantity = _parseInt(row.quantityCtrl.text) ?? 1;
        final normalizedQuantity = quantity < 1 ? 1 : quantity;
        final rowPayload = {
          'code': row.barcodeCtrl.text.trim(),
          'purchasePrice': _parseNumber(row.buyPriceCtrl.text),
          'currentState': row.currentState,
          'supplierName': _nullableText(row.supplierCtrl),
          'color': _nullableText(row.colorCtrl),
          'storage': _nullableText(row.storageCtrl),
          'sellPrice': _parseNumber(row.sellPriceCtrl.text),
          'quantity': normalizedQuantity,
        }..removeWhere((_, value) => value == null);

        for (var i = 0; i < normalizedQuantity; i++) {
          items.add(Map<String, dynamic>.from(rowPayload));
        }
      }

      await _inventoryRepo.createFromBarcodeBulk(
        currentState: _selectedCondition,
        items: items,
      );
      await _stockCtrl.fetchCategories();
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().fetchAllData();
      }
      if (!mounted) return;
      showSuccessSnackbar('${validRows.length} device row(s) imported');
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message']?.toString()
          : null;
      showErrorSnackbar(message ?? e.message ?? 'Bulk import failed');
    } catch (_) {
      showErrorSnackbar('Bulk import failed');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitCsvImport() async {
    final csvFile = _csvFile;
    if (csvFile == null) {
      showErrorSnackbar('Please choose a CSV, XLS or XLSX file first');
      return;
    }

    if (csvFile.path == null && csvFile.bytes == null) {
      showErrorSnackbar('Unable to read the selected file');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final summary = await _inventoryRepo.importCsv(
        filePath: csvFile.path,
        fileBytes: csvFile.bytes,
        filename: csvFile.name,
      );

      await _stockCtrl.fetchCategories();
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().fetchAllData();
      }

      final successCount = summary.successCount;
      final failureCount = summary.failureCount;

      if (!mounted) return;
      final successMessage = successCount != null
          ? '$successCount row(s) imported${failureCount != null ? ', $failureCount failed' : ''}'
          : 'Inventory imported successfully';
      showSuccessSnackbar(successMessage);
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message']?.toString()
          : null;
      showErrorSnackbar(message ?? e.message ?? 'CSV import failed');
    } catch (_) {
      showErrorSnackbar('CSV import failed');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _nullableText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  num? _parseNumber(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return num.tryParse(cleaned);
  }

  int? _parseInt(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  String _displayNumber(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    if (value is int) return value.toString();
    if (value is double) {
      return value % 1 == 0 ? value.toInt().toString() : value.toString();
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String? _resolveSelectableValue(List<String> options, String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) return null;
    return options.contains(rawValue) ? rawValue : null;
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  String _categoryLabel() {
    if (_selectedCategoryId == null) {
      return widget.initialCategoryName ?? 'Select category';
    }
    for (final category in _stockCtrl.categories) {
      if (category.id == _selectedCategoryId) {
        return category.name;
      }
    }
    return widget.initialCategoryName ?? 'Select category';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.pageGradient),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  if (!_isEditing) _buildTabs(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 112),
                      child: Column(
                        children: [
                          if (_isEditing || _selectedTab == 0) ...[
                            _buildDeviceIdentitySection(),
                            SizedBox(height: 14),
                            _buildTechnicalSpecsSection(),
                            SizedBox(height: 14),
                            _buildPricingSection(),
                            SizedBox(height: 14),
                            _buildManagementSection(),
                            SizedBox(height: 14),
                            _buildDetailsSection(),
                            SizedBox(height: 14),
                            _buildMediaSection(),
                            SizedBox(height: 18),
                            _buildBottomActions(),
                          ] else if (_selectedTab == 1) ...[
                            _buildBulkUploadContent(),
                          ] else ...[
                            _buildImportCsvContent(),
                          ],
                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavBar(
              selectedIndex: 1,
              onTap: (index) {
                if (index == 1) {
                  Get.offAll(() => AppGroundView(initialIndex: 1));
                  return;
                }
                Get.offAll(() => AppGroundView(initialIndex: index));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          _CircleActionButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              _isEditing ? 'Edit Device' : 'Add New Device',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final isDark = AppColors.isDark;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tabBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.tabBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.06),
            blurRadius: isDark ? 16 : 8,
            offset: Offset(0, isDark ? 6 : 3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                setState(() => _selectedTab = index);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 220),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.surfaceForeground
                        : AppColors.tabInactiveText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDeviceIdentitySection() {
    return _SectionCard(
      title: 'Device Identity',
      subtitle: 'Core identifiers for your inventory record',
      children: [
        const _FieldLabel('Product Name *'),
        SizedBox(height: 8),
        _ScanInputField(
          controller: _itemNameCtrl,
          hint: 'Enter product name',
          onScanTap: () => _openScanner(_itemNameCtrl),
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AppTextField(
                controller: _skuCtrl,
                label: 'SKU',
                hint: 'SKU-0000',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AppDropdownField<String>(
                label: 'Brand',
                value: _selectedBrand,
                hint: 'Select brand',
                items: _brands,
                itemLabel: (brand) => brand,
                onChanged: (value) => setState(() => _selectedBrand = value),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        _AppDropdownField<String>(
          label: 'Category',
          value: _selectedCategoryId,
          hint: _categoryLabel(),
          items: _stockCtrl.categories.map((category) => category.id).toList(),
          itemLabel: (id) {
            for (final category in _stockCtrl.categories) {
              if (category.id == id) {
                return category.name;
              }
            }
            return 'Unnamed';
          },
          onChanged: (value) => setState(() => _selectedCategoryId = value),
        ),
      ],
    );
  }

  Widget _buildBulkUploadContent() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _addBulkRow,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surfaceForeground,
              padding: EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: 0,
            ),
            child: Text(
              'Add New Row',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        SizedBox(height: 16),
        ..._bulkRows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _bulkRows.length - 1 ? 14 : 16,
            ),
            child: _buildBulkRowCard(index, row),
          );
        }),
        _buildDetailsSection(),
        SizedBox(height: 14),
        _buildMediaSection(),
        SizedBox(height: 18),
        _buildBulkBottomActions(),
      ],
    );
  }

  Widget _buildBulkRowCard(int index, _BulkDeviceRowForm row) {
    final isDark = AppColors.isDark;

    return _SectionCard(
      title: 'Device #${index + 1}',
      subtitle: 'Fill in the device details below.',
      trailing: _bulkRows.length > 1
          ? GestureDetector(
              onTap: () => _removeBulkRow(index),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF181F26)
                      : AppColors.fieldBackground,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.textPrimary.withValues(
                    alpha: isDark ? 0.78 : 0.72,
                  ),
                  size: 18,
                ),
              ),
            )
          : null,
      children: [
        const _FieldLabel('Barcode / Code *'),
        SizedBox(height: 8),
        _ScanInputField(
          controller: row.barcodeCtrl,
          hint: 'Scan or type device ID...',
          onScanTap: () => _openScanner(row.barcodeCtrl),
        ),
        SizedBox(height: 14),
        const _FieldLabel('Supplier Name'),
        SizedBox(height: 8),
        _ScanInputField(
          controller: row.supplierCtrl,
          hint: 'Scan or type supplier...',
          onScanTap: () => _openScanner(row.supplierCtrl),
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AppTextField(
                controller: row.colorCtrl,
                label: 'Color',
                hint: 'e.g. Black',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AppTextField(
                controller: row.storageCtrl,
                label: 'Storage / Size',
                hint: 'e.g. 128GB',
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        _AppDropdownField<String>(
          label: 'Current State',
          value: row.currentState,
          hint: 'Select state',
          items: _conditions.values.toList(),
          itemLabel: (value) => _conditions.entries
              .firstWhere((entry) => entry.value == value)
              .key,
          onChanged: (value) {
            if (value != null) {
              setState(() => row.currentState = value);
            }
          },
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AppTextField(
                controller: row.buyPriceCtrl,
                label: 'Buy Price',
                hint: '\$0',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AppTextField(
                controller: row.sellPriceCtrl,
                label: 'Sell Price',
                hint: '\$0',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        _AppTextField(
          controller: row.quantityCtrl,
          label: 'Quantity',
          hint: '1',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 14),
        const _FieldLabel('Device Image Upload'),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickBulkRowImage(index),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: AppColors.primary.withValues(
                  alpha: AppColors.isDark ? 0.48 : 0.6,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.imagePath == null
                        ? 'No file chosen'
                        : row.imagePath!.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: AppColors.isDark ? 0.45 : 0.5,
                      ),
                    ),
                    color: AppColors.primary.withValues(
                      alpha: AppColors.isDark ? 0.12 : 0.1,
                    ),
                  ),
                  child: Text(
                    row.imagePath == null ? 'In Progress' : 'Selected',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicalSpecsSection() {
    return _SectionCard(
      title: 'Technical Specs',
      subtitle: 'Hardware and serial information',
      children: [
        Row(
          children: [
            Expanded(
              child: _AppDropdownField<String>(
                label: 'Color',
                value: _selectedColor,
                hint: 'Select color',
                items: _colors,
                itemLabel: (color) => color,
                onChanged: (value) => setState(() => _selectedColor = value),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AppDropdownField<String>(
                label: 'Storage',
                value: _selectedStorage,
                hint: 'Select storage',
                items: _storages,
                itemLabel: (storage) => storage,
                onChanged: (value) => setState(() => _selectedStorage = value),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AppTextField(
                controller: _modelCtrl,
                label: 'Model Number',
                hint: 'Model number',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _ScanInputField(
                controller: _imeiCtrl,
                label: 'IMEI / Serial Number',
                hint: 'Scan or enter',
                onScanTap: () => _openScanner(_imeiCtrl),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return _SectionCard(
      title: 'Pricing & Stock',
      subtitle: 'Set your margins and inventory thresholds',
      children: [
        Row(
          children: [
            Expanded(
              child: _AppTextField(
                controller: _purchasePriceCtrl,
                label: 'Cost Price (\$)',
                hint: '0.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AppTextField(
                controller: _expectedPriceCtrl,
                label: 'Expected Price (\$)',
                hint: '0.00',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _AppTextField(
                controller: _quantityCtrl,
                label: 'Quantity',
                hint: '1',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _AppTextField(
                controller: _minStockCtrl,
                label: 'Min Stock Level',
                hint: '0',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementSection() {
    return _SectionCard(
      title: 'Management & Status',
      subtitle: 'Organize batches and condition state',
      children: [
        _AppTextField(
          controller: _groupKeyCtrl,
          label: 'Batch / Group Key',
          hint: 'Batch key',
        ),
        SizedBox(height: 14),
        _AppDropdownField<String>(
          label: 'Condition',
          value: _selectedCondition,
          hint: 'Select condition',
          items: _conditions.values.toList(),
          itemLabel: (value) {
            final match = _conditions.entries.firstWhere(
              (entry) => entry.value == value,
            );
            return match.key;
          },
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedCondition = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return _SectionCard(
      title: 'Descriptions & Details',
      subtitle: 'Add notes for your team and customers',
      children: [
        const _FieldLabel('Product Details'),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: TextField(
            controller: _detailsCtrl,
            maxLines: 6,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'e.g. Used phone, good condition...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaSection() {
    final isDark = AppColors.isDark;
    final uploadBg = isDark
        ? AppColors.primary.withValues(alpha: 0.06)
        : AppColors.primary.withValues(alpha: 0.04);
    final imageUrl = _imagePath == null ? _existingImageUrl : null;

    return _SectionCard(
      title: 'Product Media',
      subtitle: 'Upload a clear image for your inventory listing',
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: AppColors.primary.withValues(alpha: isDark ? 0.45 : 0.40),
              radius: 14,
              dashWidth: 6,
              dashGap: 5,
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: uploadBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  _imagePath == null && (imageUrl == null || imageUrl.isEmpty)
                  ? const _UploadPlaceholder()
                  : Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _imagePath != null
                              ? Image.file(
                                  File(_imagePath!),
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  imageUrl!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const _UploadPlaceholder(),
                                ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tap to change image',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.maybePop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.buttonText,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.buttonText,
                    ),
                  )
                : Text(
                    _isEditing ? 'Update Device' : 'Add To Inventory',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.buttonText,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulkBottomActions() {
    final activeRows = _bulkRows
        .where((row) => row.barcodeCtrl.text.trim().isNotEmpty)
        .length;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submitBulk,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.buttonText,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.buttonText,
                    ),
                  )
                : Text(
                    'Import $activeRows Devices',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.buttonText,
                    ),
                  ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.maybePop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportCsvContent() {
    final isDark = AppColors.isDark;
    final csvFile = _csvFile;

    return _SectionCard(
      title: 'Import CSV',
      subtitle: 'Upload your inventory spreadsheet and import it in one tap',
      children: [
        GestureDetector(
          onTap: _isSaving ? null : _pickCsvFile,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF203826)
                  : AppColors.cardBackground.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    Icons.file_upload_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  'Browse File',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'SUPPORTS .CSV . XLS . XLSX',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Maximum file size 5MB',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (csvFile != null) ...[
          SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        csvFile.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            _formatFileSize(csvFile.size),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Uploaded',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSaving ? null : _removeCsvFile,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF181F26)
                          : AppColors.fieldBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submitCsvImport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.buttonText,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.buttonText,
                    ),
                  )
                : Text(
                    'Submit & Import',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.buttonText,
                    ),
                  ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.maybePop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary, width: 1.8),
              foregroundColor: AppColors.primary,
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final cardColor = isDark
        ? AppColors.cardBackground
        : Colors.white.withValues(alpha: 0.5);
    final borderColor = isDark
        ? AppColors.fieldBorder
        : const Color(0xFFE4E7EC);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : const Color(0xFF6BA0C8).withValues(alpha: 0.10);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: isDark ? 18 : 20,
            spreadRadius: isDark ? 0 : 1,
            offset: Offset(0, isDark ? 6 : 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  const _AppTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.inputAccentBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String hint;
  final VoidCallback onScanTap;

  const _ScanInputField({
    required this.controller,
    this.label,
    required this.hint,
    required this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final field = Container(
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.inputAccentBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          // GestureDetector(
          //   onTap: onScanTap,
          //   child: Container(
          //     width: 48,
          //     height: 48,
          //     margin: EdgeInsets.all(5),
          //     decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          //     child: Icon(Icons.qr_code_scanner_rounded, color: AppColors.surfaceForeground, size: 22),
          //   ),
          // ),
        ],
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_FieldLabel(label!), SizedBox(height: 8), field],
    );
  }
}

class _AppDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onChanged;

  const _AppDropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.inputAccentBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark
                  ? AppColors.fieldBackground
                  : AppColors.cardBackground,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              hint: Text(
                hint,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(itemLabel(item)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.upload_rounded, color: AppColors.primary, size: 32),
        ),
        SizedBox(height: 20),
        Text(
          'Click to Upload',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'PNG, JPG or WEBP up to 5MB',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;

  const _DashedBorderPainter({
    required this.color,
    this.radius = 12,
    this.dashWidth = 6,
    this.dashGap = 4,
  });

  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap;
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    final backgroundColor = isDark
        ? AppColors.fieldBackground
        : AppColors.fieldBackground.withValues(alpha: 0.96);
    final borderColor = isDark
        ? AppColors.fieldBorder
        : AppColors.fieldBorder.withValues(alpha: 0.82);
    final iconColor = AppColors.textPrimary.withValues(
      alpha: isDark ? 0.95 : 0.82,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.06),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
    );
  }
}

class _BulkDeviceRowForm {
  final barcodeCtrl = TextEditingController();
  final supplierCtrl = TextEditingController();
  final colorCtrl = TextEditingController();
  final storageCtrl = TextEditingController();
  final buyPriceCtrl = TextEditingController(text: '0');
  final sellPriceCtrl = TextEditingController(text: '0');
  final quantityCtrl = TextEditingController(text: '1');
  String currentState = 'new';
  String? imagePath;

  void dispose() {
    barcodeCtrl.dispose();
    supplierCtrl.dispose();
    colorCtrl.dispose();
    storageCtrl.dispose();
    buyPriceCtrl.dispose();
    sellPriceCtrl.dispose();
    quantityCtrl.dispose();
  }
}
