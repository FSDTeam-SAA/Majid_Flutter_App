import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:majid_flutter_app/features/profile/presentation/utils/shopkeeper_qr_export.dart';

void main() {
  testWidgets('exports a complete PNG without a mounted QR widget', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await buildShopkeeperQrPng('IMS-173D5266');
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        expect(image.width, 1024);
        expect(image.height, 1200);
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba, isNotNull);
        final pixels = rgba!.buffer.asUint8List();
        // The QR's quiet zone must be opaque white for reliable scanning.
        for (final (x, y) in [(0, 0), (64, 600), (960, 600), (512, 160)]) {
          final offset = (y * image.width + x) * 4;
          expect(pixels.sublist(offset, offset + 4), [255, 255, 255, 255]);
        }
        // The top-left finder is rendered inside the quiet zone.
        final finderOffset = (216 * image.width + 120) * 4;
        expect(pixels.sublist(finderOffset, finderOffset + 4), [
          26,
          26,
          46,
          255,
        ]);
      } finally {
        image.dispose();
        codec.dispose();
      }
    });
    expect(tester.takeException(), isNull);
  });

  test('rejects a missing shopkeeper ID instead of exporting an empty QR', () {
    expect(buildShopkeeperQrPng('  '), throwsArgumentError);
  });
}
