import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:majid_flutter_app/core/network/api_service/api_client.dart';
import 'package:majid_flutter_app/features/staff/presentation/controller/staff_session_controller.dart';
import 'package:majid_flutter_app/features/staff/presentation/widgets/switch_staff_sheet.dart';

class _Api extends ApiClient {
  _Api() : super('https://example.test');
  bool fail = false;
  int calls = 0;
  @override
  Future<Response> get(String path, {Map<String, dynamic>? query}) async =>
      Response(
        requestOptions: RequestOptions(path: path),
        data: {
          'success': true,
          'data': [
            {'id': 'staff-1', 'name': 'Test Staff', 'hasPin': true},
          ],
        },
      );
  @override
  Future<Response> post(String path, {dynamic data}) async {
    calls++;
    if (fail) throw StateError('Wrong PIN/password');
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {
        'success': true,
        'data': {
          'token': 'server-token',
          'id': data['staffId'],
          'name': 'Test Staff',
        },
      },
    );
  }
}

class _Persistence extends StaffSessionPersistence {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
  @override
  Future<void> clear() async => value = null;
}

void main() {
  tearDown(() => Get.reset());
  testWidgets(
    'staff selection requires a PIN and confirmed switch closes the sheet',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      final api = _Api();
      final session = Get.put(
        StaffSessionController(api: api, persistence: _Persistence()),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSwitchStaffSheet(context),
                child: const Text('Open staff'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open staff'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Staff'));
      await tester.pumpAndSettle();
      expect(api.calls, 0);
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(session.staffName.value, 'Test Staff');
      expect(find.text('Switch Staff'), findsNothing);
      expect(tester.takeException(), null);
    },
  );

  testWidgets(
    'incorrect PIN keeps the sheet open and preserves the serving staff',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.testMode = true;
      final api = _Api()..fail = true;
      final session = Get.put(
        StaffSessionController(api: api, persistence: _Persistence()),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSwitchStaffSheet(context),
                child: const Text('Open staff'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open staff'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Staff'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '9999');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(session.staffName.value, '');
      expect(find.text('Switch Staff'), findsOneWidget);
      expect(
        find.text('Could not complete staff switching. Please retry.'),
        findsOneWidget,
      );
      expect(tester.takeException(), null);
    },
  );

  test(
    'only a server-confirmed switch changes and persists the serving staff',
    () async {
      final api = _Api();
      final persistence = _Persistence();
      final session = StaffSessionController(
        api: api,
        persistence: persistence,
      );
      await session.switchStaff('staff-1', '1234');
      expect(session.staffName.value, 'Test Staff');
      expect(jsonDecode(persistence.value!)['token'], 'server-token');
      api.fail = true;
      await expectLater(
        session.switchStaff('staff-2', '9999'),
        throwsStateError,
      );
      expect(session.staffId.value, 'staff-1');
      expect(jsonDecode(persistence.value!)['id'], 'staff-1');
      expect(session.isBusy.value, false);
    },
  );

  test(
    'owner password rejection retains staff context, confirmation clears it',
    () async {
      final api = _Api();
      final persistence = _Persistence();
      final session = StaffSessionController(
        api: api,
        persistence: persistence,
      );
      await session.switchStaff('staff-1', '1234');
      api.fail = true;
      await expectLater(session.returnToOwner('wrong'), throwsStateError);
      expect(session.staffId.value, 'staff-1');
      expect(persistence.value, isNotNull);
      api.fail = false;
      await session.returnToOwner('owner-password');
      expect(session.staffId.value, '');
      expect(persistence.value, null);
    },
  );

  test(
    'staff context survives app restart and malformed PINs never reach server',
    () async {
      final api = _Api();
      final persistence = _Persistence()
        ..value = jsonEncode({
          'token': 'saved',
          'id': 'staff-1',
          'name': 'Test Staff',
        });
      final session = StaffSessionController(
        api: api,
        persistence: persistence,
      );
      await session.restore();
      expect(session.staffName.value, 'Test Staff');
      for (final pin in ['123', '12345', 'abcd']) {
        await expectLater(
          session.switchStaff('staff-2', pin),
          throwsFormatException,
        );
      }
      expect(api.calls, 0);
      expect(session.staffId.value, 'staff-1');
    },
  );
}
