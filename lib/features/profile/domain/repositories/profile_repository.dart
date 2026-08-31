import '../entities/user_profile.dart';

/// Thrown by [ProfileRepository.updateProfile] and
/// [ProfileRepository.changePassword] when the request fails. The [message]
/// mirrors the text previously shown directly in the UI's SnackBars.
class ProfileException implements Exception {
  final String message;

  const ProfileException(this.message);

  @override
  String toString() => message;
}

abstract class ProfileRepository {
  /// Fetches the current user's profile.
  Future<UserProfile> getProfile();

  /// Updates the current user's profile. [imagePath], when provided, is
  /// uploaded as a multipart image field alongside the other fields.
  ///
  /// Throws a [ProfileException] with a user-facing message on failure.
  Future<UserProfile> updateProfile({
    required String firstName,
    required String lastName,
    String? phone,
    String? whatsappNumber,
    String? shopName,
    String? shopAddress,
    String? imagePath,
    String? currencyCode,
  });

  /// Changes the current user's password.
  ///
  /// Throws a [ProfileException] with a user-facing message on failure.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
