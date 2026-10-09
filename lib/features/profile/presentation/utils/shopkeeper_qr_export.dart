import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Renders independently of the visible widget's paint/scroll state.
Future<Uint8List> buildShopkeeperQrPng(String shopkeeperId) async {
  if (shopkeeperId.trim().isEmpty) {
    throw ArgumentError.value(shopkeeperId, 'shopkeeperId', 'ID is required');
  }

  const width = 1024;
  const height = 1200;
  const ink = Color(0xFF1A1A2E);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.white, BlendMode.src);

  void drawLabel(String text, double top, double fontSize, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: width - 128);
    painter.paint(canvas, Offset((width - painter.width) / 2, top));
    painter.dispose();
  }

  drawLabel('SCAN TO VERIFY', 80, 36, const Color(0xFF008A2E));
  canvas.save();
  canvas.translate(112, 208);
  QrPainter(
    data: shopkeeperId,
    version: QrVersions.auto,
    gapless: true,
    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ink),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: ink,
    ),
  ).paint(canvas, const Size.square(800));
  canvas.restore();
  drawLabel(shopkeeperId, 1080, 40, ink);

  final picture = recorder.endRecording();
  final ui.Image image;
  try {
    image = await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) throw StateError('Could not encode the QR image');
    return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  } finally {
    image.dispose();
  }
}
