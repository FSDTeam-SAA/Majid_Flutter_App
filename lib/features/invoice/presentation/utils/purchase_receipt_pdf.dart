import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'invoice_pdf_builder.dart' show InvoicePdfItem;

/// The purchase receipt as the website prints it: teal masthead, meta strip,
/// customer and shop panels, a teal items table and a lime total band.
abstract final class PurchaseReceiptPdf {
  static const _teal = PdfColor.fromInt(0xFF14595E);
  static const _tealSoft = PdfColor.fromInt(0xFF4E7B80);
  static const _lime = PdfColor.fromInt(0xFF8BC53F);
  static const _panel = PdfColor.fromInt(0xFFF3F6F8);
  static const _ink = PdfColor.fromInt(0xFF2B3A42);
  static const _muted = PdfColor.fromInt(0xFF7A8C94);
  static const _rule = PdfColor.fromInt(0xFFE3E9EC);
  static const _chip = PdfColor.fromInt(0xFFEEF1F4);

  static Future<File> build({
    required String fileNamePrefix,
    required DateTime createdAt,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String shopEmail,
    required String preparedBy,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String customerAddress,
    required String customerIdNumber,
    required List<InvoicePdfItem> items,
    required double totalAmount,
    required String currencyCode,
  }) async {
    final pdf = pw.Document();
    final serialCount = items
        .where((item) => item.imeiSerial.trim().isNotEmpty)
        .length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 32, 34, 30),
        build: (context) => [
          _masthead(shopPhone, shopAddress),
          pw.SizedBox(height: 16),
          pw.Container(height: 1, color: _rule),
          pw.SizedBox(height: 16),
          _metaStrip(
            createdAt,
            preparedBy,
            items.length,
            serialCount,
            currencyCode,
          ),
          pw.SizedBox(height: 16),
          _panels(
            customerName: customerName,
            customerPhone: customerPhone,
            customerEmail: customerEmail,
            customerAddress: customerAddress,
            customerIdNumber: customerIdNumber,
            shopName: shopName,
            shopAddress: shopAddress,
            shopPhone: shopPhone,
            shopEmail: shopEmail,
          ),
          pw.SizedBox(height: 20),
          _itemsTable(items, currencyCode),
          pw.SizedBox(height: 18),
          _totalBand(totalAmount, currencyCode),
          pw.SizedBox(height: 26),
          pw.Container(height: 1, color: _rule),
          pw.SizedBox(height: 16),
          _thanks(),
          pw.SizedBox(height: 18),
          _footerBar(shopPhone, shopEmail),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/${fileNamePrefix}_${createdAt.millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _masthead(String phone, String address) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 38,
                  height: 38,
                  decoration: pw.BoxDecoration(
                    color: _panel,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: _rule),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Container(
                  width: 13,
                  height: 13,
                  decoration: const pw.BoxDecoration(
                    color: _lime,
                    shape: pw.BoxShape.circle,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 7),
            _dotted([_orNa(phone), _orNa(address)]),
          ],
        ),
        pw.Text(
          'PURCHASE RECEIPT',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: _teal,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaStrip(
    DateTime createdAt,
    String preparedBy,
    int itemCount,
    int serialCount,
    String currencyCode,
  ) {
    pw.Widget group(List<(String, String)> rows, {bool divider = true}) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.only(left: 14),
          decoration: divider
              ? const pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: _rule)),
                )
              : null,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final row in rows)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '${row.$1} ',
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: _tealSoft,
                          ),
                        ),
                        pw.TextSpan(
                          text: row.$2,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        group([
          ('Date', _formatDate(createdAt)),
          ('Time', _formatTime(createdAt)),
        ], divider: false),
        group([('Prepared By', _orNa(preparedBy)), ('Items', '$itemCount')]),
        group([('Serials', '$serialCount'), ('Currency', currencyCode)]),
      ],
    );
  }

  static pw.Widget _panels({
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    required String customerAddress,
    required String customerIdNumber,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String shopEmail,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.all(16),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _panelLabel('CUSTOMER DETAILS'),
                pw.SizedBox(height: 7),
                pw.Text(
                  _orNa(customerName),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.SizedBox(height: 5),
                _panelLine('Phone: ${_orNa(customerPhone)}'),
                _panelLine('Email: ${_orNa(customerEmail)}'),
                _panelLine('Address: ${_orNa(customerAddress)}'),
                _panelLine('NID: ${_orNa(customerIdNumber)}'),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _panelLabel('SHOP INFORMATION'),
                pw.SizedBox(height: 7),
                pw.Text(
                  shopName.trim().isEmpty
                      ? 'STORE'
                      : shopName.trim().toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _lime,
                  ),
                ),
                pw.SizedBox(height: 5),
                _panelLine(_orNa(shopAddress)),
                _panelLine(_orNa(shopPhone)),
                _panelLine(_orNa(shopEmail)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _panelLabel(String text) => pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: _muted,
      letterSpacing: 0.8,
    ),
  );

  static pw.Widget _panelLine(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2.5),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: _ink)),
  );

  static pw.Widget _itemsTable(List<InvoicePdfItem> items, String code) {
    pw.Widget headerCell(String text, {pw.Alignment? align}) => pw.Container(
      alignment: align ?? pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );

    return pw.Column(
      children: [
        pw.Container(
          color: _teal,
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 46,
                child: headerCell('Product Specifications'),
              ),
              pw.Expanded(
                flex: 10,
                child: headerCell('Qty', align: pw.Alignment.center),
              ),
              pw.Expanded(flex: 28, child: headerCell('IMEI / Serials')),
              pw.Expanded(
                flex: 16,
                child: headerCell('Price', align: pw.Alignment.centerRight),
              ),
            ],
          ),
        ),
        for (final item in items) _row(item, code),
      ],
    );
  }

  static pw.Widget _row(InvoicePdfItem item, String code) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _rule)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            flex: 46,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                if (item.code.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  _dotted(item.code.split(RegExp(r'\s*[/•]\s*'))),
                ],
              ],
            ),
          ),
          pw.Expanded(
            flex: 10,
            child: pw.Center(
              child: pw.Text(
                '${item.quantity}',
                style: const pw.TextStyle(fontSize: 10, color: _ink),
              ),
            ),
          ),
          pw.Expanded(
            flex: 28,
            child: item.imeiSerial.trim().isEmpty
                ? pw.Text(
                    '-',
                    style: const pw.TextStyle(fontSize: 9, color: _muted),
                  )
                : pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3.5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _chip,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        _dot(2.4),
                        pw.Text(
                          item.imeiSerial,
                          style: const pw.TextStyle(fontSize: 8.5, color: _ink),
                        ),
                      ],
                    ),
                  ),
          ),
          pw.Expanded(
            flex: 16,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                '$code ${item.lineTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalBand(double total, String code) {
    return pw.Row(
      children: [
        pw.Spacer(flex: 45),
        pw.Expanded(
          flex: 55,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              color: _lime,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total Value:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  '$code ${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _thanks() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Thank you for your purchase!',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _teal,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Please keep this receipt for warranty and records. All item '
          'conditions were verified at the counter by both customer and store '
          'technician.',
          style: const pw.TextStyle(
            fontSize: 8.5,
            color: _muted,
            lineSpacing: 2,
          ),
        ),
      ],
    );
  }

  static pw.Widget _footerBar(String phone, String email) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _panel,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _orNa(phone),
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
          ),
          pw.Text(
            _orNa(email),
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
          ),
          pw.Text(
            'Purchase Receipt',
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
          ),
        ],
      ),
    );
  }

  /// A drawn separator dot. The built-in PDF fonts carry no U+2022, so the
  /// bullet character came out as an empty box.
  static pw.Widget _dot([double size = 2.6]) => pw.Container(
    width: size,
    height: size,
    margin: pw.EdgeInsets.symmetric(horizontal: size * 1.6),
    decoration: const pw.BoxDecoration(
      color: _muted,
      shape: pw.BoxShape.circle,
    ),
  );

  /// Renders `a • b • c` using drawn dots.
  static pw.Widget _dotted(
    List<String> parts, {
    double fontSize = 8.5,
    PdfColor color = _muted,
  }) {
    final kept = parts.where((p) => p.trim().isNotEmpty).toList();
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < kept.length; i++) ...[
          if (i > 0) _dot(),
          pw.Text(
            kept[i].trim(),
            style: pw.TextStyle(fontSize: fontSize, color: color),
          ),
        ],
      ],
    );
  }

  static String _orNa(String value) =>
      value.trim().isEmpty ? 'N/A' : value.trim();

  static String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatTime(DateTime date) {
    final isPm = date.hour >= 12;
    var hour = date.hour % 12;
    if (hour == 0) hour = 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute ${isPm ? 'PM' : 'AM'}';
  }
}
