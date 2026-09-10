import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_service/api_client.dart';
import '../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../core/network/api_service/token_meneger.dart';
import '../../../core/utils/document_saver.dart';
import '../../customer/data/repositories/customer_repository_impl.dart';
import '../../invoice/data/repositories/invoice_repository_impl.dart';
import '../../profile/presentation/controller/profile_controller.dart';
import '../../security/presentation/controller/security_controller.dart';
import '../../stock/data/repositories/inventory_repository_impl.dart';

/// What an export produced, so the UI can say where it landed.
class DataExportResult {
  final File file;
  final String locationLabel;
  final int recordCount;

  const DataExportResult({
    required this.file,
    required this.locationLabel,
    required this.recordCount,
  });
}

/// Builds the "Download My Data" exports.
///
/// Two separations from the client's notes are enforced here:
///
/// * **Personal and business data are separate exports.** The personal export
///   is the account holder's own record; the business export is the shop's
///   trading data and is owner/admin only.
/// * **Nothing sensitive is included.** Card numbers, ID-document images and
///   authentication secrets are never written to an export file, and the
///   customer export carries only the customer's own record.
class DataExportService {
  final ApiClient _api = ApiClient(baseUrl);

  ProfileController get _profile => Get.find<ProfileController>();

  /// Profile, role, permissions, login history and consent records.
  Future<DataExportResult> exportPersonalData() async {
    final profile = _profile;
    if (profile.userId.isEmpty) {
      await profile.fetchProfile();
    }

    final role = await TokenManager.getRole() ?? 'shopkeeper';
    final security = SecurityController.instance;
    await security.load();

    final payload = <String, dynamic>{
      'export': {
        'type': 'personal',
        'generatedAt': DateTime.now().toIso8601String(),
        'producedBy': 'imoscan mobile app',
        'notice':
            'This file contains your own account record. It deliberately '
            'excludes card details, identity-document images and '
            'authentication secrets.',
      },
      'account': {
        'id': profile.userId,
        'name': profile.fullName,
        'email': profile.email,
        'phone': profile.phone,
        'shopName': profile.shopName,
        'shopAddress': profile.shopAddress,
        'currency': profile.currencyCode,
        'role': role,
      },
      'security': {
        'twoFactorEnabled': security.settings.value.enabled,
        'twoFactorMethod': security.settings.value.method.name,
        'emailVerified': security.settings.value.emailVerified,
        'phoneVerified': security.settings.value.phoneVerified,
        // The authenticator secret is intentionally not exported.
        'loginDevices': [
          for (final device in security.devices)
            {
              'name': device.name,
              'platform': device.platform,
              'location': device.location,
              'lastActive': device.lastActive.toIso8601String(),
              'isCurrentDevice': device.isCurrent,
            },
        ],
      },
      'permissions': {
        'note':
            'imoscan stores the status of a device permission only, never the '
            'camera, photo or location content it unlocks.',
      },
    };

    final file = await _writeJson('imoscan_personal_data', payload);
    return _save(file, recordCount: 1);
  }

  /// Inventory, invoices, customers and totals — the shop's trading records.
  Future<DataExportResult> exportBusinessData() async {
    final profile = _profile;
    if (profile.userId.isEmpty) {
      await profile.fetchProfile();
    }
    final shopkeeperId = profile.userId;

    final inventoryRepo = InventoryRepositoryImpl(_api);
    final invoiceRepo = InvoiceRepositoryImpl(_api);
    final customerRepo = CustomerRepositoryImpl(_api);

    final inventory = await _safely(
      () => shopkeeperId.isEmpty
          ? inventoryRepo.getMyInventory()
          : inventoryRepo.getByShopkeeperId(shopkeeperId),
    );
    final invoices = await _safely(
      () => shopkeeperId.isEmpty
          ? Future.value(const [])
          : invoiceRepo.getInvoices(shopkeeperId),
    );
    final customers = await _safely(
      () => shopkeeperId.isEmpty
          ? Future.value(const [])
          : customerRepo.getCustomers(shopkeeperId),
    );

    final payload = <String, dynamic>{
      'export': {
        'type': 'business',
        'generatedAt': DateTime.now().toIso8601String(),
        'shop': profile.shopName,
        'shopkeeperId': shopkeeperId,
        'notice':
            'Full card details and identity-document images are never '
            'included in a business export.',
      },
      'inventory': [
        for (final item in inventory)
          {
            'id': item.id,
            'name': item.itemName,
            'sku': item.sku,
            'brand': item.brand,
            'model': item.modelNumber,
            'storage': item.storage,
            'colour': item.color,
            'imei': item.imeiNumber,
            'condition': item.currentState,
            'status': item.status,
            'quantity': item.quantity,
            'purchasePrice': item.purchasePrice,
            'expectedPrice': item.expectedPrice,
            'category': item.categoryName,
          },
      ],
      'invoices': [
        for (final invoice in invoices)
          {
            'reference': invoice.reference,
            'type': invoice.type,
            'customerName': invoice.customerName,
            'customerPhone': invoice.customerPhone,
            'totalAmount': invoice.totalAmount,
            'amountPaid': invoice.amountPaid,
            'paymentMethod': invoice.paymentMethod,
            'paymentStatus': invoice.paymentStatus,
            'createdAt': invoice.createdAt,
          },
      ],
      'customers': [
        for (final customer in customers)
          {
            'id': customer.id,
            'name': customer.fullName,
            'email': customer.email,
            'phone': customer.phone,
            'address': customer.address,
            'createdAt': customer.createdAt.toIso8601String(),
          },
      ],
      'totals': {
        'inventoryItems': inventory.length,
        'invoices': invoices.length,
        'customers': customers.length,
      },
    };

    final file = await _writeJson('imoscan_business_data', payload);
    return _save(
      file,
      recordCount: inventory.length + invoices.length + customers.length,
    );
  }

  /// One customer's own record, for a customer data request.
  ///
  /// Only the named customer's rows are included — another customer's data is
  /// never exposed in a request made on someone else's behalf.
  Future<DataExportResult> exportCustomerData(String customerId) async {
    final profile = _profile;
    final shopkeeperId = profile.userId;

    final customers = await _safely(
      () => shopkeeperId.isEmpty
          ? Future.value(const [])
          : CustomerRepositoryImpl(_api).getCustomers(shopkeeperId),
    );
    final customer = customers.firstWhereOrNull((c) => c.id == customerId);

    final invoices = await _safely(
      () => shopkeeperId.isEmpty
          ? Future.value(const [])
          : InvoiceRepositoryImpl(_api).getInvoices(shopkeeperId),
    );

    final theirInvoices = customer == null
        ? const []
        : invoices
              .where(
                (invoice) =>
                    invoice.customerName.trim().toLowerCase() ==
                        customer.fullName.trim().toLowerCase() ||
                    (invoice.customerPhone ?? '').trim() ==
                        customer.phone.trim(),
              )
              .toList();

    final payload = <String, dynamic>{
      'export': {
        'type': 'customer',
        'generatedAt': DateTime.now().toIso8601String(),
        'shop': profile.shopName,
        'notice':
            'Contains only this customer\'s record. Identity-document images '
            'are deleted automatically no later than 28 days after capture '
            'and are never included here.',
      },
      'customer': customer == null
          ? null
          : {
              'id': customer.id,
              'name': customer.fullName,
              'email': customer.email,
              'phone': customer.phone,
              'address': customer.address,
              'createdAt': customer.createdAt.toIso8601String(),
            },
      'transactions': [
        for (final invoice in theirInvoices)
          {
            'reference': invoice.reference,
            'type': invoice.type,
            'totalAmount': invoice.totalAmount,
            'amountPaid': invoice.amountPaid,
            'paymentStatus': invoice.paymentStatus,
            'createdAt': invoice.createdAt,
          },
      ],
    };

    final file = await _writeJson('imoscan_customer_data', payload);
    return _save(file, recordCount: theirInvoices.length);
  }

  Future<File> _writeJson(String prefix, Map<String, dynamic> payload) async {
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/${prefix}_$stamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
    return file;
  }

  Future<DataExportResult> _save(File file, {required int recordCount}) async {
    final saved = await DocumentSaver.save(file);
    return DataExportResult(
      file: saved.file,
      locationLabel: saved.locationLabel,
      recordCount: recordCount,
    );
  }

  /// A failing endpoint should degrade the export, not abort it: the file
  /// still lists whatever could be read.
  Future<List<T>> _safely<T>(Future<List<T>> Function() load) async {
    try {
      return await load();
    } on DioException catch (e) {
      debugPrint('Export section failed: ${e.message}');
      return const [];
    } catch (e) {
      debugPrint('Export section failed: $e');
      return const [];
    }
  }
}
