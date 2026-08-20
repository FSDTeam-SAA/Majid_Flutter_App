import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/repositories/staff_repository.dart';
import '../models/staff_model.dart';

class StaffRepositoryImpl implements StaffRepository {
  final ApiClient api;

  StaffRepositoryImpl(this.api);

  @override
  Future<List<StaffMember>> getStaffList(String shopkeeperId) async {
    final res = await api.get(UserEndpoints.staffByShopkeeper(shopkeeperId));
    final data = res.data['data'];
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => StaffModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<StaffMember> createStaff({
    required String shopkeeperId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await api.post(
      UserEndpoints.register,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': 'staff',
        'shopkeeperId': shopkeeperId,
      },
    );
    final user = res.data['data']['user'];
    return StaffModel.fromJson(Map<String, dynamic>.from(user));
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    await api.delete(UserEndpoints.deleteUser(staffId));
  }
}
