import 'dart:async';

/// Serializes native camera operations, including a pause arriving during start.
class ScannerSession {
  ScannerSession({
    required this.start,
    required this.stop,
    required this.dispose,
  });

  final Future<void> Function() start;
  final Future<void> Function() stop;
  final Future<void> Function() dispose;
  Future<void> _pending = Future.value();
  bool _closed = false;
  bool _wanted = false;
  bool _running = false;

  Future<void> setActive(bool active) {
    if (_closed) return _pending;
    _wanted = active;
    return _enqueue(() async {
      if (_closed) return;
      if (_wanted && !_running) {
        await start();
        _running = true;
      }
      if (!_wanted && _running) {
        await stop();
        _running = false;
      }
    });
  }

  Future<void> retry() {
    if (_closed) return _pending;
    _wanted = true;
    return _enqueue(() async {
      if (_closed || !_wanted) return;
      await stop();
      _running = false;
      await start();
      _running = true;
      if (!_wanted) {
        await stop();
        _running = false;
      }
    });
  }

  Future<void> close() {
    if (_closed) return _pending;
    _closed = true;
    _wanted = false;
    return _enqueue(() async {
      await dispose();
      _running = false;
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = _pending.then((_) => operation());
    _pending = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return result;
  }
}
