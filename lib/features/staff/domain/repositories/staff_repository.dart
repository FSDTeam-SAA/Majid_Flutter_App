import '../entities/staff_member.dart';

abstract class StaffRepository {
  Future<List<StaffMember>> getStaffList(String shopkeeperId);

  Future<StaffMember> createStaff({
    required String shopkeeperId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> deleteStaff(String staffId);
}
