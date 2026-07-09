import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

class CreateStaffMember {
  final StaffRepository repository;

  const CreateStaffMember(this.repository);

  Future<StaffMember> call({
    required String shopkeeperId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) {
    return repository.createStaff(
      shopkeeperId: shopkeeperId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      password: password,
    );
  }
}
