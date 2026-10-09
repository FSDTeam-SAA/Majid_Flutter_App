import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/core/network/api_service/api_client.dart';
import 'package:majid_flutter_app/features/security/data/security_store.dart';
import 'package:majid_flutter_app/features/security/domain/security_models.dart';
import 'package:majid_flutter_app/features/security/domain/totp.dart';
import 'package:majid_flutter_app/features/security/presentation/controller/security_controller.dart';

class _Api extends ApiClient {
  _Api() : super('https://example.test');
  Map<String, dynamic> result = {
    'success': true,
    'data': {'success': true},
  };
  bool fail = false;
  int calls = 0;
  Future<Response> _respond(String path) async {
    calls++;
    if (fail) throw StateError('Server unavailable');
    return Response(
      data: result,
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
    );
  }

  @override
  Future<Response> post(String path, {dynamic data}) => _respond(path);
  @override
  Future<Response> patch(String path, {dynamic data}) => _respond(path);
  @override
  Future<Response> delete(String path, {dynamic data}) => _respond(path);
}

class _Store extends SecurityStore {
  TwoFactorSettings? saved;
  List<LoginDevice>? savedDevices;
  NewDeviceRequest? savedRequest;
  @override
  Future<void> writeSettings(TwoFactorSettings settings) async =>
      saved = settings;
  @override
  Future<void> writeDevices(List<LoginDevice> devices) async =>
      savedDevices = List.of(devices);
  @override
  Future<void> writePendingRequest(NewDeviceRequest? request) async =>
      savedRequest = request;
}

class _DeviceController extends SecurityController {
  _DeviceController({required super.api, required super.store});
  @override
  Future<LoginDevice> describeCurrentDevice() async => LoginDevice(
    id: 'current-device',
    name: 'Test iPhone',
    platform: 'iOS',
    location: '',
    lastActive: DateTime(2026),
    isCurrent: true,
  );
}

void main() {
  final secret = 'JBSWY3DPEHPK3PXP';
  for (final confirmed in [false, true]) {
    test(
      confirmed
          ? 'device registration is persisted only after server acknowledgement'
          : 'failed device registration retains the pending request and does not trust the install',
      () async {
        final api = _Api()..fail = !confirmed;
        if (confirmed) {
          api.result = {
            'success': true,
            'data': {'deviceId': 'current-device'},
          };
        }
        final store = _Store();
        final controller = _DeviceController(api: api, store: store);
        final request = NewDeviceRequest(
          id: 'current-device',
          deviceName: 'Test iPhone',
          platform: 'iOS',
          location: '',
          requestedAt: DateTime(2026),
        );
        await controller.raiseNewDeviceRequest(request);
        expect(await controller.approvePendingRequest(), confirmed);
        expect(controller.devices.length, confirmed ? 1 : 0);
        expect(store.savedDevices?.length, confirmed ? 1 : null);
        expect(controller.pendingRequest.value, confirmed ? null : request);
        api.dio.close();
      },
    );
  }
  test(
    'device removal retains the list on server failure or unconfirmed success',
    () async {
      final api = _Api()..fail = true;
      final store = _Store();
      final controller = _DeviceController(api: api, store: store);
      controller.devices.add(
        LoginDevice(
          id: 'other-device',
          name: 'Other',
          platform: 'iOS',
          location: '',
          lastActive: DateTime(2026),
        ),
      );
      expect(await controller.removeDevice('other-device'), false);
      expect(controller.devices, hasLength(1));
      expect(store.savedDevices, null);
      api.fail = false;
      expect(await controller.removeDevice('other-device'), false);
      expect(controller.devices, hasLength(1));
      api.result = {
        'success': true,
        'data': {'removed': true},
      };
      expect(await controller.removeDevice('other-device'), true);
      expect(controller.devices, isEmpty);
      expect(store.savedDevices, isEmpty);
      api.dio.close();
    },
  );
  test(
    'valid local authenticator code does not enable 2FA after server failure',
    () async {
      final api = _Api()..fail = true;
      final store = _Store();
      final controller = SecurityController(api: api, store: store);
      expect(
        await controller.confirmAuthenticatorSetup(
          secret: secret,
          code: Totp.code(secret),
        ),
        false,
      );
      expect(controller.settings.value.enabled, false);
      expect(store.saved, null);
    },
  );

  test(
    'confirmed server setup marks authenticator configured without persisting the secret',
    () async {
      final api = _Api();
      final store = _Store();
      final controller = SecurityController(api: api, store: store);
      expect(
        await controller.confirmAuthenticatorSetup(
          secret: secret,
          code: Totp.code(secret),
        ),
        true,
      );
      expect(store.saved!.hasAuthenticator, true);
      expect(store.saved!.isConfirmed, true);
      expect(store.saved!.toJson().containsKey('authenticatorSecret'), false);
    },
  );

  test(
    'a new device can verify authenticator through server without a cached secret',
    () async {
      final api = _Api()
        ..result = {
          'success': true,
          'data': {'valid': true},
        };
      final controller = SecurityController(api: api, store: _Store());
      controller.settings.value = const TwoFactorSettings(
        method: TwoFactorMethod.authenticator,
        hasAuthenticator: true,
      );
      expect(await controller.verifyChallenge('123456'), true);
      expect(api.calls, 1);
      api.result = {
        'success': true,
        'data': {'valid': false},
      };
      expect(await controller.verifyChallenge('123456'), false);
      api.result = {'success': true};
      expect(await controller.verifyChallenge('123456'), false);
    },
  );

  test(
    'cached local secret cannot bypass server rejection or outage',
    () async {
      final api = _Api()..fail = true;
      final controller = SecurityController(api: api, store: _Store());
      controller.settings.value = TwoFactorSettings(
        enabled: true,
        method: TwoFactorMethod.authenticator,
        authenticatorSecret: secret,
      );
      expect(await controller.verifyChallenge(Totp.code(secret)), false);
    },
  );

  test('failed settings updates keep previously confirmed settings', () async {
    final api = _Api()..fail = true;
    final store = _Store();
    final controller = SecurityController(api: api, store: store);
    expect(await controller.setEnabled(true), false);
    expect(await controller.setMethod(TwoFactorMethod.authenticator), false);
    expect(controller.settings.value.enabled, false);
    expect(controller.settings.value.method, TwoFactorMethod.email);
    expect(store.saved, null);
  });

  test(
    'challenge delivery requires an explicit sent acknowledgement',
    () async {
      final api = _Api();
      final controller = SecurityController(api: api, store: _Store());
      expect(
        (await controller.sendChallenge(
          method: TwoFactorMethod.sms,
          destination: '0123456789',
        )).sent,
        false,
      );
      api.result = {
        'success': true,
        'data': {'sent': true, 'destination': 'a***@example.test'},
      };
      final dispatch = await controller.sendChallenge(
        method: TwoFactorMethod.email,
        destination: 'a@example.test',
      );
      expect(dispatch.sent, true);
      expect(dispatch.destination, 'a***@example.test');
    },
  );
}
