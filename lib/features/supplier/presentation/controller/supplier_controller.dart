import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../data/repositories/supplier_repository_impl.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/create_supplier.dart';
import '../../domain/usecases/delete_supplier.dart';
import '../../domain/usecases/get_suppliers.dart';

enum SupplierStatusFilter { active, inactive, all }

class SupplierController extends GetxController {
  late final GetSuppliers _getSuppliers;
  late final CreateSupplier _createSupplier;
  late final DeleteSupplier _deleteSupplier;

  final isLoading = true.obs;
  final isCreating = false.obs;
  final errorMessage = ''.obs;
  final suppliers = <Supplier>[].obs;
  final searchQuery = ''.obs;
  final statusFilter = SupplierStatusFilter.active.obs;

  @override
  void onInit() {
    super.onInit();
    final repository = SupplierRepositoryImpl(ApiClient(baseUrl));
    _getSuppliers = GetSuppliers(repository);
    _createSupplier = CreateSupplier(repository);
    _deleteSupplier = DeleteSupplier(repository);
    fetchSuppliers();
  }

  bool? get _isActiveFilterValue {
    switch (statusFilter.value) {
      case SupplierStatusFilter.active:
        return true;
      case SupplierStatusFilter.inactive:
        return false;
      case SupplierStatusFilter.all:
        return null;
    }
  }

  Future<void> fetchSuppliers() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      suppliers.value = await _getSuppliers(search: searchQuery.value, isActive: _isActiveFilterValue);
    } catch (e) {
      errorMessage.value = 'Failed to load suppliers';
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
    fetchSuppliers();
  }

  void setStatusFilter(SupplierStatusFilter filter) {
    statusFilter.value = filter;
    fetchSuppliers();
  }

  Future<bool> createSupplier({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    isCreating.value = true;
    try {
      final supplier = await _createSupplier(name: name, phone: phone, email: email, address: address, notes: notes);
      suppliers.insert(0, supplier);
      return true;
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> deleteSupplier(String id) async {
    await _deleteSupplier(id);
    suppliers.removeWhere((s) => s.id == id);
  }
}
