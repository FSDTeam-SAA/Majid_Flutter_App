import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/core/network/api_service/api_client.dart';

class _FailureAdapter implements HttpClientAdapter {
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      '{"message":"Unavailable"}',
      503,
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
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  for (final method in ['POST', 'PUT', 'DELETE']) {
    test('$method is not retried after a transient failure', () async {
      final api = ApiClient('https://example.test');
      final adapter = _FailureAdapter();
      api.dio.httpClientAdapter = adapter;
      await expectLater(
        api.dio.request(
          '/invoice',
          data: {'amount': 100},
          options: Options(method: method),
        ),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, 1);
      api.dio.close();
    });
  }
}
