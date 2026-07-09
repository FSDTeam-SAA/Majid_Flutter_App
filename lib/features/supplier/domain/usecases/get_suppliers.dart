import '../entities/supplier.dart';
import '../repositories/supplier_repository.dart';

class GetSuppliers {
  final SupplierRepository repository;

  const GetSuppliers(this.repository);

  Future<List<Supplier>> call({String? search, bool? isActive}) {
    return repository.getSuppliers(search: search, isActive: isActive);
  }
}
