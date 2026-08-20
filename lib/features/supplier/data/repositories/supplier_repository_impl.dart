import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/supplier_repository.dart';
import '../models/supplier_model.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final ApiClient api;

  SupplierRepositoryImpl(this.api);

  @override
  Future<List<Supplier>> getSuppliers({String? search, bool? isActive}) async {
    final res = await api.get(
      SupplierEndpoints.all,
      query: {
        'limit': 100,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (isActive != null) 'isActive': isActive.toString(),
      },
    );
    final data = res.data['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => SupplierModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<Supplier> createSupplier({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final res = await api.post(
      SupplierEndpoints.create,
      data: {
        'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (address != null && address.isNotEmpty) 'address': address,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return SupplierModel.fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<Supplier> updateSupplier(
    String id, {
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? isActive,
  }) async {
    final res = await api.patch(
      SupplierEndpoints.byId(id),
      data: {
        'name': ?name,
        'phone': ?phone,
        'email': ?email,
        'address': ?address,
        'notes': ?notes,
        'isActive': ?isActive,
      },
    );
    return SupplierModel.fromJson(Map<String, dynamic>.from(res.data['data']));
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await api.delete(SupplierEndpoints.byId(id));
  }
}
