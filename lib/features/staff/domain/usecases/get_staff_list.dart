import '../entities/staff_member.dart';
import '../repositories/staff_repository.dart';

class GetStaffList {
  final StaffRepository repository;

  const GetStaffList(this.repository);

  Future<List<StaffMember>> call(String shopkeeperId) {
    return repository.getStaffList(shopkeeperId);
  }
}
