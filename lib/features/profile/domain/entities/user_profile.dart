/// The current user's profile — combines account fields (name, email) with
/// shop details (shop name/address) and the credit balance shown throughout
/// the profile feature.
class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final double balance;
  final String shopName;
  final String shopAddress;
  final String whatsappNumber;
  final String phone;
  final String imageUrl;

  const UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.balance,
    required this.shopName,
    required this.shopAddress,
    required this.whatsappNumber,
    required this.phone,
    required this.imageUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  static const empty = UserProfile(
    id: '',
    firstName: '',
    lastName: '',
    email: '',
    balance: 0,
    shopName: '',
    shopAddress: '',
    whatsappNumber: '',
    phone: '',
    imageUrl: '',
  );
}
