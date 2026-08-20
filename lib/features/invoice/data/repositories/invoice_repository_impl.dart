import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoice_repository.dart';
import '../../presentation/controller/invoice_data.dart';

class InvoiceRepositoryImpl implements InvoiceRepository {
  final ApiClient _api;

  InvoiceRepositoryImpl(this._api);

  @override
  Future<void> createInvoice(FormData payload) async {
    await _api.post(InvoiceEndpoints.create, data: payload);
  }

  @override
  Future<List<Invoice>> getInvoices(String shopkeeperId) async {
    final res = await _api.get(InvoiceEndpoints.byShopkeeper(shopkeeperId));
    final data = res.data['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => _invoiceFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<InvoiceProduct>> getInventoryItems() async {
    final res = await _api.get(InventoryEndpoints.myInventory);
    final data = res.data['data'];
    if (data is! List) {
      throw const FormatException('Invalid inventory response');
    }
    return data
        .whereType<Map>()
        .map((item) => _productFromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<String> extractNid({File? frontImage, File? backImage}) async {
    final payload = FormData.fromMap({
      if (frontImage != null)
        'nid_front': await MultipartFile.fromFile(frontImage.path),
      if (backImage != null)
        'nid_back': await MultipartFile.fromFile(backImage.path),
    });

    final Response res;
    try {
      res = await _api.post(OcrEndpoints.extractNid, data: payload);
    } on DioException catch (e) {
      throw InvoiceException(
        e.response?.data?['message']?.toString() ??
            'Failed to extract NID from image.',
      );
    }

    final data = res.data['data'];
    final nidNumber = data is Map ? data['nidNumber']?.toString() : null;
    if (nidNumber == null || nidNumber.isEmpty) {
      throw const InvoiceException(
        'No valid NID number found in the selected image.',
      );
    }
    return nidNumber;
  }

  Invoice _invoiceFromJson(Map<String, dynamic> item) {
    final invoiceFile = item['invoice'];
    final pdfUrl = invoiceFile is Map ? invoiceFile['url']?.toString() : null;
    return Invoice(
      id: item['_id']?.toString() ?? '',
      type: item['type']?.toString() ?? 'invoice',
      totalAmount: (item['totalAmount'] as num?)?.toDouble(),
      createdAt: item['createdAt']?.toString(),
      customerName: _invoiceCustomerName(item),
      pdfUrl: pdfUrl,
    );
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
      imeiSerial:
          item['imeiNumber']?.toString() ??
          item['serialNumber']?.toString() ??
          '',
      price: price,
      color: AppColors.primary,
      category: _categoryFromJson(item),
      storage: item['storage']?.toString() ?? '',
      colorName: item['color']?.toString() ?? '',
      condition: item['currentState']?.toString() ?? '',
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
}
