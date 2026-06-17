class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool isVerified;
  final String? phone;
  final String? street;
  final String? location;
  final String? postalCode;
  final String? dateOfBirth;
  final String? imageUrl;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.isVerified = false,
    this.phone,
    this.street,
    this.location,
    this.postalCode,
    this.dateOfBirth,
    this.imageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? false,
      phone: json['phone'],
      street: json['street'],
      location: json['location'],
      postalCode: json['postalCode'],
      dateOfBirth: json['dateOfBirth'],
      imageUrl: (json['image'] is Map) ? json['image']['url'] : null,
    );
  }

  String get fullName => '$firstName $lastName';
}

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;

  AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
