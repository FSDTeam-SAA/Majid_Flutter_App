import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/core/network/api_service/api_client.dart';
import 'package:majid_flutter_app/features/scan/data/repositories/imei_repository_impl.dart';
import 'package:majid_flutter_app/features/scan/domain/entities/scan_service_option.dart';
import 'package:majid_flutter_app/features/scan/domain/repositories/imei_repository.dart';
import 'package:majid_flutter_app/features/scan/presentation/pages/bulk_scan_page.dart';
import 'package:majid_flutter_app/features/scan/presentation/pages/scan_device_page.dart';

class _Api extends ApiClient {
  _Api(this.results) : super('https://example.test');
  final List<dynamic> results;
  Map<String, dynamic>? payload;

  @override
  Future<Response> post(String path, {dynamic data}) async {
    payload = Map<String, dynamic>.from(data as Map);
    return Response(
      requestOptions: RequestOptions(path: path),
      data: {'data': results},
    );
  }
}

class _Scans extends Fake implements ImeiRepository {
  final pending = Completer<List<Map<String, dynamic>>>();
  final service = ScanDropdownOption('Device check', 'Free', serviceId: 7);
  List<String>? submitted;
  int calls = 0;

  @override
  Future<List<ScanDropdownOption>> getServices() async => [service];
  @override
  Future<ScanHistoryResult> getHistoryResult({int? page, int? limit}) async =>
      ScanHistoryResult(items: [], total: 0);
  @override
  Future<List<Map<String, dynamic>>> checkImeis({
    required List<String> imeis,
    required int serviceId,
  }) {
    expect(serviceId, 7);
    calls++;
    submitted = imeis;
    return pending.future;
  }
}

void main() {
  test(
    'bulk response preserves order, failures, missing results and report service',
    () async {
      final api = _Api([
        {'imei': 'SERIAL22', 'ok': false, 'message': 'Not found'},
        {
          'imei': '351297474660682',
          'ok': true,
          'data': {
            'parsedProviderData': {'device': 'Phone'},
          },
        },
      ]);
      final results = await ImeiRepositoryImpl(api).checkImeis(
        imeis: ['351297474660682', 'SERIAL22', 'SERIAL33'],
        serviceId: 7,
      );
      expect(api.payload, {
        'imei': ['351297474660682', 'SERIAL22', 'SERIAL33'],
        'serviceId': 7,
      });
      expect(results.map((r) => r['imei']), [
        '351297474660682',
        'SERIAL22',
        'SERIAL33',
      ]);
      expect(results.first['ok'], true);
      expect(results.every((r) => r['serviceId'] == 7), true);
      expect(results[1]['message'], 'Not found');
      expect(results[2]['ok'], false);
    },
  );

  testWidgets(
    'bulk entry deduplicates, prevents double submits and updates recent scans',
    (tester) async {
      sessionScans.clear();
      addTearDown(sessionScans.clear);
      final repository = _Scans();
      await tester.pumpWidget(
        MaterialApp(home: ScanDevicePage(repository: repository)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bulk checking'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('bulk-identifiers')),
        '351297474660682\nserial22,351297474660682; SERIAL33',
      );
      await tester.ensureVisible(find.text('Check devices'));
      await tester.tap(find.text('Check devices'));
      await tester.pump();
      expect(repository.submitted, ['351297474660682', 'SERIAL22', 'SERIAL33']);
      expect(repository.calls, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      repository.pending.complete([
        {
          'imei': '351297474660682',
          'ok': true,
          'serviceId': 7,
          'data': {
            'parsedProviderData': {'device': 'iPhone 17 Pro'},
          },
        },
        {'imei': 'SERIAL22', 'ok': false, 'message': 'Not found'},
        {
          'imei': 'SERIAL33',
          'ok': true,
          'serviceId': 7,
          'data': {
            'parsedProviderData': {'device': 'iPhone 17'},
          },
        },
      ]);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('2 of 3 reports ready'));
      expect(find.text('2 of 3 reports ready'), findsOneWidget);
      expect(sessionScans.map((s) => s.imei), ['SERIAL33', '351297474660682']);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(BulkScanPage), findsNothing);
      expect(find.text('iPhone 17 Pro'), findsOneWidget);
      expect(find.text('See All (2)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty, malformed and oversized lists never submit checks', (
    tester,
  ) async {
    final repository = _Scans();
    await tester.pumpWidget(
      MaterialApp(
        home: BulkScanPage(
          repository: repository,
          services: [repository.service],
          onResults: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Check devices'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter at least one IMEI or serial number.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'BAD!');
    await tester.tap(find.text('Check devices'));
    await tester.pumpAndSettle();
    expect(find.text('Use letters and numbers only: BAD!'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      List.generate(21, (i) => 'SERIAL$i').join('\n'),
    );
    await tester.ensureVisible(find.text('Check devices'));
    await tester.tap(find.text('Check devices'));
    await tester.pumpAndSettle();
    expect(find.text('Check up to 20 devices at a time.'), findsOneWidget);
    expect(repository.calls, 0);
  });
}
