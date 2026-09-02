import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/scan/presentation/utils/device_certificate_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  test('renders the device verification certificate', () async {
    final file = await DeviceCertificatePdf.build(
      deviceName: 'Y21 4G+64G',
      imei: '861142051584447',
      serialNumber: 'N/A',
      fields: const {
        'MANUFACTURER': 'VIVO',
        'MODEL NAME': 'Y21 4G+64G',
        'MARKETING NAME': 'Y21',
        'MODEL CODE': 'V2111',
        'COLOR': 'Metallic Blue',
      },
      riskScore: 0.12,
      riskDescription: '',
    );

    expect(await file.length(), greaterThan(1000));
    final out = File('${Directory.systemTemp.path}/certificate_preview.pdf');
    await file.copy(out.path);
    // ignore: avoid_print
    print('CERT_PATH=${out.path}');
  });
}
