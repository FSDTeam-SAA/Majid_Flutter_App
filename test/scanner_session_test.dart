import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/scan/presentation/utils/scanner_session.dart';

void main() {
  test('repeated resume does not start the native camera twice', () async {
    final gate = Completer<void>();
    var starts = 0;
    final session = ScannerSession(
      start: () async {
        starts++;
        await gate.future;
      },
      stop: () async {},
      dispose: () async {},
    );
    final first = session.setActive(true);
    await Future<void>.delayed(Duration.zero);
    final second = session.setActive(true);
    gate.complete();
    await Future.wait([first, second]);
    expect(starts, 1);
    await session.close();
  });

  test(
    'pause during startup stops the camera after startup finishes',
    () async {
      final gate = Completer<void>();
      final calls = <String>[];
      final session = ScannerSession(
        start: () async {
          calls.add('start');
          await gate.future;
        },
        stop: () async => calls.add('stop'),
        dispose: () async => calls.add('dispose'),
      );
      final starting = session.setActive(true);
      await Future<void>.delayed(Duration.zero);
      final pausing = session.setActive(false);
      gate.complete();
      await Future.wait([starting, pausing]);
      expect(calls, ['start', 'stop']);
      await session.setActive(true);
      expect(calls, ['start', 'stop', 'start']);
      await session.close();
    },
  );

  test(
    'retry stops before starting and recovers from a failed start',
    () async {
      final calls = <String>[];
      var attempts = 0;
      final session = ScannerSession(
        start: () async {
          calls.add('start');
          if (attempts++ == 0) throw StateError('camera failed');
        },
        stop: () async => calls.add('stop'),
        dispose: () async {},
      );
      await expectLater(session.setActive(true), throwsStateError);
      await session.retry();
      expect(calls, ['start', 'stop', 'start']);
      await session.setActive(true);
      expect(calls.length, 3);
      await session.close();
    },
  );

  test(
    'closing during start serializes stop and disposal and prevents restart',
    () async {
      final gate = Completer<void>();
      final calls = <String>[];
      final session = ScannerSession(
        start: () async {
          calls.add('start');
          await gate.future;
        },
        stop: () async => calls.add('stop'),
        dispose: () async => calls.add('dispose'),
      );
      final starting = session.setActive(true);
      await Future<void>.delayed(Duration.zero);
      final closing = session.close();
      gate.complete();
      await Future.wait([starting, closing]);
      await session.setActive(true);
      await session.retry();
      expect(calls, ['start', 'stop', 'dispose']);
    },
  );

  test(
    'a queued start is cancelled when the page closes before it runs',
    () async {
      var starts = 0;
      final session = ScannerSession(
        start: () async {
          starts++;
        },
        stop: () async {},
        dispose: () async {},
      );
      final starting = session.setActive(true);
      await session.close();
      await starting;
      expect(starts, 0);
    },
  );
}
