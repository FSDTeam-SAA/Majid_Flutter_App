import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/scan/domain/entities/scan_item.dart';
import 'package:majid_flutter_app/features/scan/domain/entities/scan_service_option.dart';
import 'package:majid_flutter_app/features/scan/domain/repositories/imei_repository.dart';
import 'package:majid_flutter_app/features/scan/presentation/pages/all_scan_history_page.dart';
import 'package:majid_flutter_app/features/scan/presentation/pages/scan_device_page.dart';
import 'package:majid_flutter_app/features/scan/presentation/widgets/scan_item_card.dart';

class _Scans implements ImeiRepository {
  _Scans(this.count);
  final int count;
  int historyCalls = 0;

  @override
  Future<List<ScanDropdownOption>> getServices() async => [
    ScanDropdownOption('Device check', 'Free', serviceId: 1),
  ];

  @override
  Future<ScanHistoryResult> getHistoryResult({int? page, int? limit}) async {
    historyCalls++;
    return ScanHistoryResult(
      items: List.generate(count < (limit ?? count) ? count : limit!, (index) {
        return ScanItem(
          name: 'Device $index',
          imei: '1234567890123${index.toString().padLeft(2, '0')}',
          status: 'Clean',
          createdAt: DateTime(2026, 10, 9).subtract(Duration(minutes: index)),
        );
      }),
      total: count,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NavigationObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    super.didPush(route, previousRoute);
  }
}

Future<void> _showScans(
  WidgetTester tester,
  _Scans repository, {
  required TargetPlatform platform,
  NavigatorObserver? observer,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: platform),
      navigatorObservers: [?observer],
      home: ScanDevicePage(repository: repository),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _reachBottom(WidgetTester tester) async {
  final scrollable = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(ScanDevicePage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
  await tester.pumpAndSettle();
}

void main() {
  setUp(sessionScans.clear);
  tearDown(sessionScans.clear);

  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    testWidgets(
      'six scans open history only after a further drag on $platform',
      (tester) async {
        final repository = _Scans(6);
        final observer = _NavigationObserver();
        await _showScans(
          tester,
          repository,
          platform: platform,
          observer: observer,
        );
        expect(find.byType(ScanItemCard), findsNWidgets(6));
        expect(find.byType(AllScanHistoryPage), findsNothing);
        await _reachBottom(tester);
        // Merely reaching the bottom, or a programmatic scroll, must not navigate.
        expect(find.byType(AllScanHistoryPage), findsNothing);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
        expect(find.byType(AllScanHistoryPage), findsOneWidget);
        expect(observer.pushes, 2);
        expect(repository.historyCalls, 2);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
        await tester.pumpAndSettle();
        expect(find.byType(AllScanHistoryPage), findsNothing);
        expect(observer.pushes, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('fewer than six scans do not open history when overscrolled', (
    tester,
  ) async {
    final repository = _Scans(5);
    await _showScans(tester, repository, platform: TargetPlatform.iOS);
    await _reachBottom(tester);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AllScanHistoryPage), findsNothing);
    expect(repository.historyCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preview shows six items and See All still opens the full history',
    (tester) async {
      final repository = _Scans(12);
      await _showScans(tester, repository, platform: TargetPlatform.iOS);
      expect(find.byType(ScanItemCard), findsNWidgets(6));
      await tester.ensureVisible(find.text('See All (12)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See All (12)'));
      await tester.pumpAndSettle();
      expect(find.byType(AllScanHistoryPage), findsOneWidget);
      expect(find.text('12 Records'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
