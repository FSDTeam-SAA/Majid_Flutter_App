import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/entities/staff_member.dart';
import '../../domain/usecases/create_staff_member.dart';
import '../../domain/usecases/delete_staff_member.dart';
import '../../domain/usecases/get_staff_list.dart';

class StaffController extends GetxController {
  late final GetStaffList _getStaffList;
  late final CreateStaffMember _createStaffMember;
  late final DeleteStaffMember _deleteStaffMember;
  late final ProfileController _profileCtrl;

  final isLoading = true.obs;
  final isCreating = false.obs;
  final errorMessage = ''.obs;
  final staffList = <StaffMember>[].obs;

  int get totalStaff => staffList.length;
  int get verifiedCount =>
      staffList.where((s) => s.status == StaffStatus.verified).length;
  int get pendingCount =>
      staffList.where((s) => s.status == StaffStatus.pending).length;

  @override
  void onInit() {
    super.onInit();
    final repository = StaffRepositoryImpl(ApiClient(baseUrl));
    _getStaffList = GetStaffList(repository);
    _createStaffMember = CreateStaffMember(repository);
    _deleteStaffMember = DeleteStaffMember(repository);
    _profileCtrl = Get.find<ProfileController>();
    fetchStaff();
  }

  Future<String> _resolveShopkeeperId() async {
    var shopkeeperId = _profileCtrl.userId;
    if (shopkeeperId.isEmpty) {
      await _profileCtrl.fetchProfile();
      shopkeeperId = _profileCtrl.userId;
    }
    if (shopkeeperId.isEmpty) {
      throw Exception(
        'Could not verify your shop account. Please reopen Staff Management and try again.',
      );
    }
    return shopkeeperId;
  }

  Future<void> fetchStaff() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final shopkeeperId = await _resolveShopkeeperId();
      staffList.value = await _getStaffList(shopkeeperId);
    } catch (e) {
      errorMessage.value = 'Failed to load staff members';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createStaff({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    isCreating.value = true;
    try {
      final shopkeeperId = await _resolveShopkeeperId();
      final staff = await _createStaffMember(
        shopkeeperId: shopkeeperId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      );
      staffList.add(staff);
      return true;
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> deleteStaff(String staffId) async {
    await _deleteStaffMember(staffId);
    staffList.removeWhere((s) => s.id == staffId);
  }
}
