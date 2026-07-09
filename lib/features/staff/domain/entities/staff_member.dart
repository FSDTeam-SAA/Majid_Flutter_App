enum StaffStatus { verified, pending }

class StaffMember {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String jobRole;
  final StaffStatus status;
  final DateTime createdAt;

  const StaffMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.jobRole,
    required this.status,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();
}
