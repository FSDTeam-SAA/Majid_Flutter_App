import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer.dart';

class CustomerController extends GetxController {
  late final CustomerRepositoryImpl _repository;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final customers = <Customer>[].obs;
  final searchQuery = ''.obs;

  List<Customer> get filteredCustomers {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return customers;
    return customers.where((c) {
      return c.fullName.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _repository = CustomerRepositoryImpl(ApiClient(baseUrl));
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final profileCtrl = Get.find<ProfileController>();
      var shopkeeperId = profileCtrl.userId;
      if (shopkeeperId.isEmpty) {
        await profileCtrl.fetchProfile();
        shopkeeperId = profileCtrl.userId;
      }
      if (shopkeeperId.isEmpty) {
        customers.clear();
        return;
      }
      customers.value = await _repository.getCustomers(shopkeeperId);
    } catch (e) {
      errorMessage.value = 'Failed to load customers';
    } finally {
      isLoading.value = false;
    }
  }

  void setSearchQuery(String value) => searchQuery.value = value;

  Future<bool> createCustomer({
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
  }) async {
    isSaving.value = true;
    try {
      final customer = await _repository.createCustomer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
      );
      customers.insert(0, customer);
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateCustomer({
    required String id,
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
  }) async {
    isSaving.value = true;
    try {
      final updated = await _repository.updateCustomer(
        id: id,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        address: address,
      );
      final index = customers.indexWhere((c) => c.id == id);
      if (index != -1) customers[index] = updated;
      return true;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> deleteCustomer(String id) async {
    await _repository.deleteCustomer(id);
    customers.removeWhere((c) => c.id == id);
  }
}
