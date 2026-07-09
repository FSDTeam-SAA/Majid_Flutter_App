import '../repositories/supplier_repository.dart';

class DeleteSupplier {
  final SupplierRepository repository;

  const DeleteSupplier(this.repository);

  Future<void> call(String id) {
    return repository.deleteSupplier(id);
  }
}
