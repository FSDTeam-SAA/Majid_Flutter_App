import '../../domain/entities/staff_member.dart';

class StaffModel extends StaffMember {
  const StaffModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phone,
    required super.jobRole,
    required super.status,
    required super.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      jobRole: json['jobRole']?.toString() ?? 'Staff',
      status: json['isVerified'] == true
          ? StaffStatus.verified
          : StaffStatus.pending,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'jobRole': jobRole,
      'isVerified': status == StaffStatus.verified,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
