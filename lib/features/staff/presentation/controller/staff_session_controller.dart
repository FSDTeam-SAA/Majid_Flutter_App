import 'dart:convert';

import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/network/api_service/token_meneger.dart';

class StaffSessionPersistence {
  Future<String?> read() => TokenManager.getStaffSession();
  Future<void> write(String value) => TokenManager.saveStaffSession(value);
  Future<void> clear() => TokenManager.clearStaffSession();
}

class StaffSessionController extends GetxController {
  final ApiClient _api;
  final StaffSessionPersistence _persistence;
  final staffName = ''.obs;
  final staffId = ''.obs;
  final isBusy = false.obs;

  StaffSessionController({ApiClient? api, StaffSessionPersistence? persistence})
    : _api = api ?? ApiClient(baseUrl),
      _persistence = persistence ?? StaffSessionPersistence();

  static StaffSessionController get instance =>
      Get.isRegistered<StaffSessionController>()
      ? Get.find<StaffSessionController>()
      : Get.put(StaffSessionController(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    restore();
  }

  Future<void> restore() async {
    final raw = await _persistence.read();
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['token'] is! String ||
          (data['token'] as String).isEmpty ||
          data['id'] is! String ||
          (data['id'] as String).isEmpty) {
        throw const FormatException('Invalid staff session');
      }
      staffName.value = data['name'] as String;
      staffId.value = data['id'] as String;
    } catch (_) {
      staffName.value = 'Staff session';
      staffId.value = 'invalid';
    }
  }

  Future<List<Map<String, dynamic>>> members() async {
    final response = await _api.get(UserEndpoints.staffSessionMembers);
    return (response.data['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> switchStaff(String id, String pin) async {
    if (isBusy.value) {
      throw StateError('Staff switching is already in progress.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const FormatException('Enter exactly four PIN digits.');
    }
    isBusy.value = true;
    try {
      final response = await _api.post(
        UserEndpoints.switchStaff,
        data: {'staffId': id, 'pin': pin},
      );
      final data = Map<String, dynamic>.from(response.data['data'] as Map);
      if (response.data['success'] != true ||
          data['token'] is! String ||
          (data['token'] as String).isEmpty ||
          data['name'] is! String ||
          data['id'] != id) {
        throw const FormatException('Could not verify the staff session.');
      }
      await _persistence.write(jsonEncode(data));
      staffName.value = data['name'] as String;
      staffId.value = id;
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> returnToOwner(String password) async {
    if (isBusy.value) {
      throw StateError('Staff switching is already in progress.');
    }
    isBusy.value = true;
    try {
      final response = await _api.post(
        UserEndpoints.returnToOwner,
        data: {'password': password},
      );
      if (response.data['success'] != true) {
        throw const FormatException('Could not verify the owner.');
      }
      await _persistence.clear();
      staffName.value = '';
      staffId.value = '';
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> setPin(String id, String pin, String password) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const FormatException('Enter exactly four PIN digits.');
    }
    final response = await _api.put(
      UserEndpoints.staffPin(id),
      data: {'pin': pin, 'password': password},
    );
    if (response.data['success'] != true) {
      throw const FormatException('Could not save the staff PIN.');
    }
  }
}
