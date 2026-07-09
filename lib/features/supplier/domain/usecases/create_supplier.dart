import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class CreateSupplier {
  final SupplierRepository repository;

  const CreateSupplier(this.repository);

  Future<Supplier> call({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return repository.createSupplier(
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
  }
}
