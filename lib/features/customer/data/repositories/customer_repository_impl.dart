import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/customer.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final ApiClient api;

  CustomerRepositoryImpl(this.api);

  Customer _fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now();
    return Customer(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      createdAt: createdAt,
    );
  }

  @override
  Future<List<Customer>> getCustomers(String shopkeeperId) async {
    final res = await api.get(CustomerEndpoints.byShopkeeper(shopkeeperId));
    final data = res.data['data'];
    if (data is! List) return [];
    return data.whereType<Map>().map((item) => _fromJson(Map<String, dynamic>.from(item))).toList();
  }

  @override
  Future<Customer> createCustomer({
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
  }) async {
    final res = await api.post(
      CustomerEndpoints.create,
      data: {
        'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (address != null && address.isNotEmpty) 'address': address,
      },
    );
    return _fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
  }) async {
    final res = await api.put(
      CustomerEndpoints.update(id),
      data: {
        'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      },
    );
    return _fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await api.delete(CustomerEndpoints.delete(id));
  }
}
