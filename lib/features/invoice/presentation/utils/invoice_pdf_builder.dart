import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePdfItem {
  final String name;
  final String code;
  final int quantity;
  final double unitPrice;

  const InvoicePdfItem({
    required this.name,
    required this.code,
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
                  _formatCurrency(totalAmount),
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
          _buildItemsTable(items),
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
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _formatCurrency(totalAmount),
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
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
    final safePrefix = fileNamePrefix.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final safeNumber = invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${directory.path}/${safePrefix}_$safeNumber.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
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
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
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

  static pw.Widget _buildItemsTable(List<InvoicePdfItem> items) {
    final rows = items.isEmpty
        ? [
            ['No items selected', '-', '0', _formatCurrency(0), _formatCurrency(0)],
          ]
        : items
              .map(
                (item) => [
                  item.name,
                  item.code.isEmpty ? '-' : item.code,
                  '${item.quantity}',
                  _formatCurrency(item.unitPrice),
                  _formatCurrency(item.lineTotal),
                ],
              )
              .toList();

    return pw.TableHelper.fromTextArray(
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      headerStyle: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headers: const ['Item', 'Code', 'Qty', 'Unit Price', 'Total'],
      data: rows,
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

  static String _formatCurrency(double value) {
    final amount = value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '£$amount';
  }
}
