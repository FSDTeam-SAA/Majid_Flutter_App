import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers(String shopkeeperId);

  Future<Customer> createCustomer({
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
  });

  Future<Customer> updateCustomer({
    required String id,
    required String firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
  });

  Future<void> deleteCustomer(String id);
}
