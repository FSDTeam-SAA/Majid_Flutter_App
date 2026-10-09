import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/core/network/api_service/api_client.dart';
import 'package:majid_flutter_app/core/network/api_service/token_meneger.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      '{"success":true}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => FlutterSecureStorage.setMockInitialValues({
      'access_token': 'owner-access',
      'staff_session_v1': jsonEncode({
        'token': 'staff-context',
        'id': 'staff-1',
        'name': 'Test Staff',
      }),
    }),
  );
  test(
    'business requests carry context while staff switching retains owner authentication',
    () async {
      final api = ApiClient('https://example.test');
      final adapter = _Adapter();
      api.dio.httpClientAdapter = adapter;
      await api.get('/api/v1/invoice/all');
      await api.post(
        '/api/v1/user/staff-session/switch',
        data: {'staffId': 'staff-2', 'pin': '4321'},
      );
      expect(
        adapter.requests.first.headers['Authorization'],
        'Bearer owner-access',
      );
      expect(
        adapter.requests.first.headers['X-Staff-Session'],
        'staff-context',
      );
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer owner-access',
      );
      expect(
        adapter.requests.last.headers.containsKey('X-Staff-Session'),
        false,
      );
      api.dio.close();
    },
  );
  test(
    'logout and a new account login remove the previous staff session',
    () async {
      await TokenManager.clearToken();
      expect(await TokenManager.getStaffSession(), null);
      await TokenManager.saveStaffSession('{"token":"old-context"}');
      await TokenManager.saveToken(
        accessToken: 'new-owner',
        refreshToken: 'new-refresh',
      );
      expect(await TokenManager.getStaffSession(), null);
    },
  );
  test(
    'corrupt staff context never silently becomes an owner request',
    () async {
      final api = ApiClient('https://example.test');
      final adapter = _Adapter();
      api.dio.httpClientAdapter = adapter;
      for (final value in [
        '{"name":"Staff"}',
        '{"token":""}',
        'invalid-json',
      ]) {
        await TokenManager.saveStaffSession(value);
        await api.get('/api/v1/invoice/all');
        expect(adapter.requests.last.headers['X-Staff-Session'], 'invalid');
      }
      api.dio.close();
    },
  );
}
