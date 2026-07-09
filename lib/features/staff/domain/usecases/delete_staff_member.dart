import '../repositories/staff_repository.dart';

class DeleteStaffMember {
  final StaffRepository repository;

  const DeleteStaffMember(this.repository);

  Future<void> call(String staffId) {
    return repository.deleteStaff(staffId);
  }
}
