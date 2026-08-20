import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePdfItem {
  final String name;
  final String code;
  final String imeiSerial;
  final int quantity;
  final double unitPrice;

  const InvoicePdfItem({
    required this.name,
    required this.code,
    this.imeiSerial = '',
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;
}

class InvoicePdfBuilder {
  static Future<File> build({
    required String fileNamePrefix,
    required String invoiceTitle,
    required String invoiceNumber,
    required DateTime createdAt,
    required String shopName,
    required String shopAddress,
    required String shopEmail,
    required String shopPhone,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerAddress,
    required String paymentType,
    required List<InvoicePdfItem> items,
    required double totalAmount,
    String currencySymbol = '\$',
    double? amountPaid,
    String? footerNote,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    invoiceTitle,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Invoice #: $invoiceNumber',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Date: ${_formatDate(createdAt)}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  pw.Text(
                    'Payment: ${_safeValue(paymentType)}',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  _formatCurrency(totalAmount, currencySymbol),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _buildInfoCard(
                  title: 'From',
                  lines: [
                    _safeValue(shopName),
                    _safeValue(shopEmail),
                    _safeValue(shopPhone),
                    _safeValue(shopAddress),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: _buildInfoCard(
                  title: 'Bill To',
                  lines: [
                    _safeValue(customerName),
                    _safeValue(customerEmail),
                    _safeValue(customerPhone),
                    _safeValue(customerAddress),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          _buildItemsTable(items, currencySymbol),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 220,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Total Amount',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _formatCurrency(totalAmount, currencySymbol),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (amountPaid != null) ...[
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 6),
                    _buildAmountRow('Amount Paid', amountPaid, currencySymbol),
                    pw.SizedBox(height: 4),
                    _buildAmountRow(
                      'Balance Due',
                      totalAmount - amountPaid,
                      currencySymbol,
                      bold: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (footerNote != null && footerNote.trim().isNotEmpty) ...[
            pw.SizedBox(height: 24),
            pw.Text(
              footerNote.trim(),
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final safePrefix = fileNamePrefix.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final safeNumber = invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}/${safePrefix}_$safeNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> buildPurchaseReceipt({
    required String fileNamePrefix,
    required String invoiceNumber,
    required DateTime createdAt,
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String customerName,
    required String customerPhone,
    required String customerIdNumber,
    required List<InvoicePdfItem> items,
    required double totalAmount,
    String currencySymbol = '\$',
  }) async {
    final pdf = pw.Document();
    const navy = PdfColor.fromInt(0xFF0F172A);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => [
          pw.Container(height: 6, color: navy),
          pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PURCHASE RECEIPT',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Date: ${_formatLongDate(createdAt)}',
                        style: pw.TextStyle(fontSize: 10, color: navy),
                      ),
                      pw.Text(
                        'Time: ${_formatTime(createdAt)}',
                        style: pw.TextStyle(fontSize: 10, color: navy),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: _buildShadedCard(
                        title: 'CUSTOMER DETAILS',
                        rows: [
                          ('NAME', _safeValue(customerName)),
                          ('PHONE', _safeValue(customerPhone)),
                          ('GOVT ID / NID', _safeValue(customerIdNumber)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: _buildShadedCard(
                        title: 'SHOP INFORMATION',
                        rows: [],
                        plainLines: [
                          shopName,
                          shopAddress,
                          shopPhone,
                        ].map(_safeValue).toList(),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text(
                  'PURCHASED DEVICES',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                _buildPurchaseDevicesTable(items, navy, currencySymbol),
                pw.SizedBox(height: 18),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'TOTAL VALUE',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          _formatCurrency(totalAmount, currencySymbol),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final safePrefix = fileNamePrefix.replaceAll(
      RegExp(r'[^a-zA-Z0-9_-]'),
      '_',
    );
    final safeNumber = invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}/${safePrefix}_$safeNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildShadedCard({
    required String title,
    required List<(String, String)> rows,
    List<String> plainLines = const [],
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 10),
          ...rows.map(
            (row) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    row.$1,
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    row.$2,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...plainLines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPurchaseDevicesTable(
    List<InvoicePdfItem> items,
    PdfColor headerColor,
    String currencySymbol,
  ) {
    final rows = items.isEmpty
        ? [
            ['No devices added', '0', _formatCurrency(0, currencySymbol)],
          ]
        : items
              .map(
                (item) => [
                  item.code.isEmpty ? item.name : '${item.name}\n${item.code}',
                  '${item.quantity}',
                  _formatCurrency(item.lineTotal, currencySymbol),
                ],
              )
              .toList();

    return pw.TableHelper.fromTextArray(
      headerDecoration: pw.BoxDecoration(color: headerColor),
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headers: const ['PRODUCT SPECIFICATIONS', 'QTY', 'VALUE'],
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1.4),
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
      },
      data: rows,
    );
  }

  static String _formatLongDate(DateTime value) {
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
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  static String _formatTime(DateTime value) {
    final hour24 = value.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '${hour12.toString().padLeft(2, '0')}:$minute $period';
  }

  static pw.Widget _buildInfoCard({
    required String title,
    required List<String> lines,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    List<InvoicePdfItem> items,
    String currencySymbol,
  ) {
    final rows = items.isEmpty
        ? [
            [
              'No items selected',
              '-',
              '-',
              '0',
              _formatCurrency(0, currencySymbol),
              _formatCurrency(0, currencySymbol),
            ],
          ]
        : items
              .map(
                (item) => [
                  item.name,
                  item.code.isEmpty ? '-' : item.code,
                  item.imeiSerial.isEmpty ? '-' : item.imeiSerial,
                  '${item.quantity}',
                  _formatCurrency(item.unitPrice, currencySymbol),
                  _formatCurrency(item.lineTotal, currencySymbol),
                ],
              )
              .toList();

    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      headerStyle: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headers: const [
        'Item',
        'Code',
        'IMEI/Serial',
        'Qty',
        'Unit Price',
        'Total',
      ],
      data: rows,
    );
  }

  static pw.Widget _buildAmountRow(
    String label,
    double value,
    String currencySymbol, {
    bool bold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: bold ? 13 : 11,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: bold ? PdfColors.black : PdfColors.grey700,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(_formatCurrency(value, currencySymbol), style: style),
      ],
    );
  }

  static String _safeValue(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'N/A' : trimmed;
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _formatCurrency(double value, String symbol) {
    final amount = value
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
    return '$symbol$amount';
  }
}
