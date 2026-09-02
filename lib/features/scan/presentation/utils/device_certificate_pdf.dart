import 'dart:io';

import 'package:barcode/barcode.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// The "Device Verification Certificate" the website hands out after a scan.
abstract final class DeviceCertificatePdf {
  static const _navy = PdfColor.fromInt(0xFF1E293B);
  static const _slate = PdfColor.fromInt(0xFF64748B);
  static const _panelHead = PdfColor.fromInt(0xFFEEF2F7);
  static const _border = PdfColor.fromInt(0xFFE3E8EF);
  static const _blue = PdfColor.fromInt(0xFF3B82F6);
  static const _shield = PdfColor.fromInt(0xFF84CC16);
  static const _amberHead = PdfColor.fromInt(0xFFFCD34D);
  static const _amberBorder = PdfColor.fromInt(0xFFF0B429);
  static const _amberTint = PdfColor.fromInt(0xFFFFFBEB);
  static const _warn = PdfColor.fromInt(0xFFB45309);

  static Future<File> build({
    required String deviceName,
    required String imei,
    required Map<String, String> fields,
    required double riskScore,
    required String riskDescription,
    String serialNumber = 'N/A',
    String provider = 'sickw',
    String serviceId = '75',
  }) async {
    final pdf = pw.Document();
    final score = (riskScore * 100).round();
    final level = score <= 33
        ? 'LOW'
        : score <= 66
        ? 'MEDIUM'
        : 'HIGH';

    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/imoscan_logo.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _headerBand(logo, imei),
            pw.SizedBox(height: 22),
            _panel(
              'Device Details',
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 74,
                    height: 74,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _border),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: _shieldGlyph(20),
                  ),
                  pw.SizedBox(width: 26),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _detailRow('Device:', _orNa(deviceName)),
                        _detailRow('IMEI:', _orNa(imei)),
                        _detailRow('Serial Number:', _orNa(serialNumber)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            _panel('Verification Summary', _summaryGrid(fields)),
            pw.SizedBox(height: 18),
            _riskPanel(level, score, riskDescription),
            pw.SizedBox(height: 26),
            _footer(imei, provider, serviceId),
          ],
        ),
      ),
    );

    final directory = await getTemporaryDirectory();
    final safeImei = imei.replaceAll(RegExp(r'[^0-9A-Za-z]'), '');
    final file = File(
      '${directory.path}/Certificate_${safeImei.isEmpty ? 'device' : safeImei}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _headerBand(pw.MemoryImage? logo, String imei) {
    return pw.Stack(
      children: [
        pw.Center(
          child: pw.Column(
            children: [
              if (logo != null)
                pw.SizedBox(height: 34, child: pw.Image(logo))
              else
                pw.Text(
                  'imoscan',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: _shield,
                  ),
                ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Device Verification Certificate',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Check before you buy',
                style: const pw.TextStyle(fontSize: 10.5, color: _slate),
              ),
            ],
          ),
        ),
        pw.Positioned(
          right: 0,
          top: 0,
          child: pw.BarcodeWidget(
            barcode: Barcode.qrCode(),
            data: imei.trim().isEmpty ? 'imoscan' : imei.trim(),
            width: 74,
            height: 74,
            drawText: false,
          ),
        ),
      ],
    );
  }

  static pw.Widget _panel(String title, pw.Widget body) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            color: _panelHead,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 11,
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            child: body,
          ),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 108,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10, color: _navy),
            ),
          ),
        ],
      ),
    );
  }

  /// Two columns of ticked facts, as on the website.
  static pw.Widget _summaryGrid(Map<String, String> fields) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = fields[key.toUpperCase()]?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return 'N/A';
    }

    final entries = <(String, String)>[
      ('Manufacturer', pick(['manufacturer', 'brand'])),
      ('Model Name', pick(['model name', 'model', 'device name'])),
      ('Marketing Name', pick(['marketing name'])),
      ('Model Code', pick(['model code', 'model number'])),
      ('Color', pick(['color', 'colour'])),
    ];

    final rows = <pw.Widget>[];
    for (var i = 0; i < entries.length; i += 2) {
      final left = entries[i];
      final right = i + 1 < entries.length ? entries[i + 1] : null;
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 14),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _checkFact(left.$1, left.$2)),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: right == null
                    ? pw.SizedBox()
                    : _checkFact(right.$1, right.$2),
              ),
            ],
          ),
        ),
      );
    }
    return pw.Column(children: rows);
  }

  static pw.Widget _checkFact(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _checkGlyph(_blue),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$label:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _navy,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                value,
                style: const pw.TextStyle(fontSize: 10, color: _slate),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _riskPanel(String level, int score, String conclusion) {
    const reviewed = [
      'Activation data reviewed',
      'Blacklist signal reviewed',
      'SIM lock signal reviewed',
      'Repair history signal reviewed',
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _amberBorder),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            color: _amberHead,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 11,
            ),
            child: pw.Text(
              'Risk Analysis (AI Powered)',
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
                color: _navy,
              ),
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    _checkGlyph(_amberBorder),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'Overall Risk Level:',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _amberBorder,
                        // The pdf package does not clamp oversized radii the
                        // way Flutter does; 999 drew a broken path that
                        // flooded the page.
                        borderRadius: pw.BorderRadius.circular(9),
                      ),
                      child: pw.Text(
                        '$level ($score/100)',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  'Explanation:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _slate,
                  ),
                ),
                pw.SizedBox(height: 8),
                for (final line in reviewed)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 7),
                    child: pw.Row(
                      children: [
                        _checkGlyph(_blue, size: 9),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          line,
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: _navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _shieldGlyph(10),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Text(
                        'Conclusion: ${_conclusion(conclusion)}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy,
                          lineSpacing: 2.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            color: _amberTint,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _warning(
                  'Always match IMEI / serials with the physical device before '
                  'purchase.',
                ),
                pw.SizedBox(height: 7),
                _warning(
                  'Boxes that are sealed and status says ACTIVATED should be '
                  'reviewed carefully.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _warning(String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '!',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: _warn,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(
              fontSize: 9,
              color: _warn,
              lineSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _footer(String imei, String provider, String serviceId) {
    final tail = imei.length > 8 ? imei.substring(imei.length - 8) : imei;

    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _shieldGlyph(9),
            pw.SizedBox(width: 6),
            pw.Text(
              'Report ID: IMO-$tail',
              style: const pw.TextStyle(fontSize: 9, color: _slate),
            ),
            pw.SizedBox(width: 22),
            pw.Text(
              'Generated On: ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: _slate),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Provider: $provider | Service ID: $serviceId',
          style: const pw.TextStyle(fontSize: 8, color: _slate),
        ),
      ],
    );
  }

  /// Small tick inside a ring - the pdf package has no icon font here.
  static pw.Widget _checkGlyph(PdfColor color, {double size = 10}) {
    return pw.Container(
      width: size,
      height: size,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Text(
        'v',
        style: pw.TextStyle(
          fontSize: size * 0.62,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _shieldGlyph(double size) {
    return pw.Container(
      width: size * 1.1,
      height: size * 1.3,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _shield, width: 1.4),
        borderRadius: pw.BorderRadius.vertical(
          top: pw.Radius.circular(size * 0.22),
          bottom: pw.Radius.circular(size * 0.55),
        ),
      ),
    );
  }

  static String _conclusion(String description) {
    final text = description.trim();
    if (text.isNotEmpty) return text;
    return 'The device shows no signs of blacklist, finance lock, or carrier '
        'lock. It appears to be clean and unlocked.';
  }

  static String _orNa(String value) =>
      value.trim().isEmpty ? 'N/A' : value.trim();

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }
}
