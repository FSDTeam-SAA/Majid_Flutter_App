import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../../../app_ground_view.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../home/presentation/controller/home_controller.dart';
import '../controller/stock_controller.dart';

class AddNewDevicePage extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;

  const AddNewDevicePage({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<AddNewDevicePage> createState() => _AddNewDevicePageState();
}

class _AddNewDevicePageState extends State<AddNewDevicePage> {
  late final ApiClient _api;
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

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _stockCtrl = Get.find<StockController>();
    _selectedCategoryId = widget.initialCategoryId;
    _bulkRows.add(_BulkDeviceRowForm());
    _primeCategories();
  }

  Future<void> _primeCategories() async {
    if (_stockCtrl.categories.isNotEmpty) return;
    await _stockCtrl.fetchCategories();
    if (mounted) setState(() {});
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

      final payload = _imagePath != null
          ? FormData.fromMap({
              ...data,
              'image': await MultipartFile.fromFile(_imagePath!),
            })
          : data;

      await _api.post(InventoryEndpoints.create, data: payload);
      await _stockCtrl.fetchCategories();
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().fetchAllData();
      }
      if (!mounted) return;
      showSuccessSnackbar('Device added to inventory');
      Navigator.pop(context, true);
    } on DioException catch (e) {
      showErrorSnackbar(
        e.response?.data?['message'] ?? 'Failed to add device to inventory',
      );
    } catch (_) {
      showErrorSnackbar('Failed to add device to inventory');
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

      final payload = {'currentState': _selectedCondition, 'items': items};

      await _api.post(InventoryEndpoints.createFromBarcodeBulk, data: payload);
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

    setState(() => _isSaving = true);
    try {
      MultipartFile uploadFile;
      if (csvFile.path != null && csvFile.path!.isNotEmpty) {
        uploadFile = await MultipartFile.fromFile(
          csvFile.path!,
          filename: csvFile.name,
        );
      } else if (csvFile.bytes != null) {
        uploadFile = MultipartFile.fromBytes(
          csvFile.bytes!,
          filename: csvFile.name,
        );
      } else {
        showErrorSnackbar('Unable to read the selected file');
        return;
      }

      final payload = FormData.fromMap({'file': uploadFile});
      final response = await _api.post(
        InventoryEndpoints.importCsv,
        data: payload,
      );

      await _stockCtrl.fetchCategories();
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().fetchAllData();
      }

      final responseData = response.data;
      final responseBody = responseData is Map ? responseData['data'] : null;
      final summary = responseBody is Map ? responseBody['summary'] : null;
      final successCount = summary is Map ? summary['successCount'] : null;
      final failureCount = summary is Map ? summary['failureCount'] : null;

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
      if (category['_id']?.toString() == _selectedCategoryId) {
        return category['name']?.toString() ?? 'Select category';
      }
    }
    return widget.initialCategoryName ?? 'Select category';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: 1,
        onTap: (index) {
          if (index == 1) {
            Get.offAll(() => AppGroundView(initialIndex: 1));
            return;
          }
          Get.offAll(() => AppGroundView(initialIndex: index));
        },
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildTabs(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 112),
                  child: Column(
                    children: [
                      if (_selectedTab == 0) ...[
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
              'Add New Device',
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
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFF192638),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Color(0xFF223342)),
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
                    color: isSelected ? Colors.black : Color(0xFFA9B3C1),
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
          onScanTap: () => showErrorSnackbar('Scanner integration coming soon'),
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
          items: _stockCtrl.categories
              .map((category) => category['_id']?.toString())
              .whereType<String>()
              .toList(),
          itemLabel: (id) {
            for (final category in _stockCtrl.categories) {
              if (category['_id']?.toString() == id) {
                return category['name']?.toString() ?? 'Unnamed';
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
              foregroundColor: Colors.black,
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
                  color: Color(0xFF181F26),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white70,
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
          onScanTap: () => showErrorSnackbar('Scanner integration coming soon'),
        ),
        SizedBox(height: 14),
        const _FieldLabel('Supplier Name'),
        SizedBox(height: 8),
        _ScanInputField(
          controller: row.supplierCtrl,
          hint: 'Scan or type supplier...',
          onScanTap: () => showErrorSnackbar('Scanner integration coming soon'),
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
              border: Border.all(color: Color(0xFF67E45D)),
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
                    border: Border.all(color: Color(0xFF67E45D)),
                    color: Color(0x1A67E45D),
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
                onScanTap: () =>
                    showErrorSnackbar('Scanner integration coming soon'),
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
            borderRadius: BorderRadius.circular(18),
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
    return _SectionCard(
      title: 'Product Media',
      subtitle: 'Upload a clear image for your inventory listing',
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                style: BorderStyle.solid,
              ),
            ),
            child: _imagePath == null
                ? const _UploadPlaceholder()
                : Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_imagePath!),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
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
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
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
                      color: Colors.black,
                    ),
                  )
                : Text(
                    'Add To Inventory',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
              foregroundColor: Colors.black,
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
                      color: Colors.black,
                    ),
                  )
                : Text(
                    'Import $activeRows Devices',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.maybePop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportCsvContent() {
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
              color: Color(0xFF203826),
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
                      color: Color(0xFF181F26),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
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
              foregroundColor: Colors.black,
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
                      color: Colors.black,
                    ),
                  )
                : Text(
                    'Submit & Import',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
              foregroundColor: AppColors.textPrimary,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 10),
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
        color: Color(0xFFDCE5EE),
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
            border: Border.all(color: Color(0xFF67E45D)),
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
        border: Border.all(color: Color(0xFF67E45D)),
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
          GestureDetector(
            onTap: onScanTap,
            child: Container(
              width: 48,
              height: 48,
              margin: EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.black,
                size: 22,
              ),
            ),
          ),
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
            border: Border.all(color: Color(0xFF67E45D)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: Color(0xFF121C23),
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
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(
            Icons.file_upload_outlined,
            color: AppColors.primary,
            size: 28,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Click to Upload',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'PNG, JPG or WEBP up to 5MB',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.fieldBorder,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
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
