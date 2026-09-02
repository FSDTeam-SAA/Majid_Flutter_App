import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One line on the invoice. Verification details are optional so the same
/// document serves a scanned device sale and a plain shop invoice.
class VerifiedInvoiceItem {
  final String name;
  final String imei;
  final String serial;
  final String warranty;
  final String purchaseDate;
  final String warrantyType;
  final String blacklist;
  final String simLock;
  final String activation;
  final bool isVerified;
  final int quantity;
  final double lineTotal;

  const VerifiedInvoiceItem({
    required this.name,
    required this.quantity,
    required this.lineTotal,
    this.imei = '',
    this.serial = '',
    this.warranty = '',
    this.purchaseDate = '',
    this.warrantyType = '',
    this.blacklist = '',
    this.simLock = '',
    this.activation = '',
    this.isVerified = false,
  });
}

/// The IMEI lookup panel, shown only when a scan backs the invoice.
class VerifiedInvoiceApiSummary {
  final String coverage;
  final String registration;
  final String replaced;
  final String openRepair;
  final int riskScore;
  final String aiSummary;

  const VerifiedInvoiceApiSummary({
    this.coverage = 'N/A',
    this.registration = 'N/A',
    this.replaced = 'N/A',
    this.openRepair = 'N/A',
    this.riskScore = 0,
    this.aiSummary = 'N/A',
  });
}

/// The invoice layout the client signed off on: green header rule, contact
/// strip, verification column and total band. Used by both the Smart Invoice
/// and the Create Invoice flow so every document looks the same.
abstract final class VerifiedInvoicePdf {
  static const _green = PdfColor.fromInt(0xFF6BB024);
  static const _greenDark = PdfColor.fromInt(0xFF5A9A1E);
  static const _greenTint = PdfColor.fromInt(0xFFF3F9E8);
  static const _panelTint = PdfColor.fromInt(0xFFF7FBEE);
  static const _ink = PdfColor.fromInt(0xFF1F2933);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _line = PdfColor.fromInt(0xFFE2E5E9);
  static const _unpaid = PdfColor.fromInt(0xFFE8622A);

  static Future<File> build({
    required String fileName,
    required String invoiceNumber,
    required DateTime createdAt,
    required String shopName,
    required String shopEmail,
    required String shopPhone,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerAddress,
    required String paymentLabel,
    required bool isPaid,
    required String currencySymbol,
    required List<VerifiedInvoiceItem> items,
    String subtitle = 'VERIFIED DEVICE SALE',
    VerifiedInvoiceApiSummary? apiSummary,
  }) async {
    final pdf = pw.Document();
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final money = _money(currencySymbol, subtotal);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 28),
        build: (context) => [
          _header(shopName, shopPhone, shopEmail, subtitle),
          pw.SizedBox(height: 14),
          pw.Container(height: 3, color: _green),
          pw.SizedBox(height: 18),
          _contactStrip(customerName, customerPhone, customerEmail),
          pw.SizedBox(height: 18),
          _billToRow(
            customerName,
            customerAddress,
            customerPhone,
            customerEmail,
            invoiceNumber,
            createdAt,
            paymentLabel,
          ),
          pw.SizedBox(height: 18),
          _itemsTable(items, currencySymbol),
          if (apiSummary != null) ...[
            pw.SizedBox(height: 16),
            _apiSummary(apiSummary),
          ],
          pw.SizedBox(height: 16),
          _noteAndTotals(apiSummary, money, isPaid),
          pw.SizedBox(height: 28),
          _signatures(),
          pw.SizedBox(height: 14),
          pw.Center(
            child: pw.Text(
              'Thank you for your purchase. Keep this invoice for warranty '
              'and resale records.',
              style: pw.TextStyle(fontSize: 8.5, color: _muted),
            ),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _header(
    String shopName,
    String phone,
    String email,
    String subtitle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 26,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              shopName.isEmpty ? 'Imoscan' : shopName,
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Verified device seller',
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '${_orNa(phone)} | ${_orNa(email)}',
              style: pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _contactStrip(String name, String phone, String email) {
    return pw.Row(
      children: [
        _contactBox('CUSTOMER', _orNa(name)),
        pw.SizedBox(width: 8),
        _contactBox('PHONE', _orNa(phone)),
        pw.SizedBox(width: 8),
        _contactBox('EMAIL', _orNa(email)),
      ],
    );
  }

  static pw.Widget _contactBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: pw.BoxDecoration(
          color: _greenTint,
          border: pw.Border.all(color: _line),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7.5,
                color: _muted,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _billToRow(
    String name,
    String address,
    String phone,
    String email,
    String invoiceNumber,
    DateTime createdAt,
    String paymentLabel,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _muted,
                  letterSpacing: 1.1,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                _orNa(name),
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              if (address.trim().isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  address,
                  style: pw.TextStyle(fontSize: 9.5, color: _muted),
                ),
              ],
              pw.SizedBox(height: 3),
              pw.Text(
                '${_orNa(phone)} | ${_orNa(email)}',
                style: pw.TextStyle(fontSize: 9.5, color: _muted),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Container(
          width: 210,
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: _line),
          ),
          child: pw.Column(
            children: [
              _metaRow('Invoice No.', invoiceNumber, withDivider: true),
              _metaRow(
                'Invoice Date',
                _formatDate(createdAt),
                withDivider: true,
              ),
              _metaRow('Payment', _titleCase(paymentLabel), withDivider: false),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _metaRow(
    String label,
    String value, {
    required bool withDivider,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5),
      decoration: withDivider
          ? const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _line)),
            )
          : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _muted)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(
    List<VerifiedInvoiceItem> items,
    String currencySymbol,
  ) {
    pw.Widget headerCell(String text, {pw.Alignment? align}) {
      return pw.Container(
        alignment: align ?? pw.Alignment.centerLeft,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    return pw.Column(
      children: [
        pw.Container(
          color: _green,
          child: pw.Row(
            children: [
              pw.Expanded(flex: 32, child: headerCell('ITEM')),
              pw.Expanded(flex: 26, child: headerCell('IMEI / SERIAL')),
              pw.Expanded(flex: 24, child: headerCell('VERIFICATION')),
              pw.Expanded(
                flex: 8,
                child: headerCell('QTY', align: pw.Alignment.center),
              ),
              pw.Expanded(
                flex: 16,
                child: headerCell('AMOUNT', align: pw.Alignment.centerRight),
              ),
            ],
          ),
        ),
        for (final item in items) _itemRow(item, currencySymbol),
      ],
    );
  }

  static pw.Widget _itemRow(VerifiedInvoiceItem item, String currencySymbol) {
    final details = <String>[
      if (item.warranty.trim().isNotEmpty) 'Warranty: ${item.warranty}',
      if (item.purchaseDate.trim().isNotEmpty)
        'Purchase date: ${item.purchaseDate}',
      if (item.warrantyType.trim().isNotEmpty)
        'Warranty type: ${item.warrantyType}',
    ];
    final checks = <String>[
      if (item.blacklist.trim().isNotEmpty) 'Blacklist: ${item.blacklist}',
      if (item.simLock.trim().isNotEmpty) 'SIM lock: ${item.simLock}',
      if (item.activation.trim().isNotEmpty) 'Activation: ${item.activation}',
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _line)),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 32,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                if (details.isNotEmpty) pw.SizedBox(height: 6),
                for (final line in details) _subLine(line),
              ],
            ),
          ),
          pw.Expanded(
            flex: 26,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'IMEI: ${_orDash(item.imei)}',
                  style: const pw.TextStyle(fontSize: 9, color: _ink),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Serial: ${_orDash(item.serial)}',
                  style: const pw.TextStyle(fontSize: 9, color: _ink),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 24,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.isVerified ? 'AI checked' : 'Not verified',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: item.isVerified ? _greenDark : _muted,
                  ),
                ),
                if (checks.isNotEmpty) pw.SizedBox(height: 5),
                for (final line in checks) _subLine(line),
              ],
            ),
          ),
          pw.Expanded(
            flex: 8,
            child: pw.Center(
              child: pw.Text(
                '${item.quantity}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
            ),
          ),
          pw.Expanded(
            flex: 16,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                _money(currencySymbol, item.lineTotal),
                style: pw.TextStyle(
                  fontSize: 12,
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

  static pw.Widget _subLine(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8, color: _muted),
      ),
    );
  }

  static pw.Widget _apiSummary(VerifiedInvoiceApiSummary summary) {
    pw.Widget cell(String label, String value) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
                letterSpacing: 0.8,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _panelTint,
        border: pw.Border.all(color: _line),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'IMEI API Response Summary',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              cell('COVERAGE', summary.coverage),
              cell('REGISTRATION', summary.registration),
              cell('REPLACED', summary.replaced),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              cell('OPEN REPAIR', summary.openRepair),
              cell('RISK', '${summary.riskScore}/100'),
              cell('AI', summary.aiSummary),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _noteAndTotals(
    VerifiedInvoiceApiSummary? summary,
    String money,
    bool isPaid,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: summary == null
              ? pw.SizedBox()
              : pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _line),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Device Verification Note',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.SizedBox(height: 7),
                      pw.Text(
                        'This invoice includes the IMEI verification status available '
                        'at the time of sale. Buyer should match the IMEI on the '
                        'physical device before completing ownership transfer.',
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: _muted,
                          lineSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Risk score: ${summary.riskScore}/100 | ${summary.aiSummary}',
                        style: const pw.TextStyle(fontSize: 8.5, color: _muted),
                      ),
                    ],
                  ),
                ),
        ),
        pw.SizedBox(width: 16),
        pw.SizedBox(
          width: 210,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Subtotal',
                      style: const pw.TextStyle(fontSize: 10, color: _muted),
                    ),
                    pw.Text(
                      money,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(height: 1, color: _line),
              pw.SizedBox(height: 8),
              pw.Container(
                color: _green,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      money,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  isPaid ? 'PAID' : 'UNPAID',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: isPaid ? _greenDark : _unpaid,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _signatures() {
    pw.Widget line(String label) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(height: 1, color: _ink),
            pw.SizedBox(height: 6),
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ),
      );
    }

    return pw.Row(
      children: [
        line('Seller Signature'),
        pw.SizedBox(width: 40),
        line('Customer Signature'),
      ],
    );
  }

  static String _money(String symbol, double amount) =>
      '$symbol${amount.toStringAsFixed(2)}';

  static String _orNa(String value) =>
      value.trim().isEmpty ? 'N/A' : value.trim();

  static String _orDash(String value) =>
      value.trim().isEmpty ? '-' : value.trim();

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

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
