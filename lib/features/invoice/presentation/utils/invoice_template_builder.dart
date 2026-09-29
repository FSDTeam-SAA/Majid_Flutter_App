import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/invoice_template_settings.dart';
import 'invoice_pdf_builder.dart' show InvoicePdfItem;
import 'purchase_receipt_pdf.dart';
import 'verified_invoice_pdf.dart';

/// Central PDF orchestrator for invoices.
///
/// Respects the user's chosen invoice design template (Classic Editorial,
/// Warm Minimalist, Neo Bold, Modern Retail, Nordic Slate, or Default) while
/// keeping the Smart Invoice and Default theme completely untouched.
class InvoiceTemplateBuilder {
  /// Builds a Sales Invoice using the requested or currently preferred template.
  static Future<File> buildSalesInvoice({
    required String fileName,
    required String invoiceNumber,
    required DateTime createdAt,
    required String shopName,
    required String shopEmail,
    required String shopPhone,
    String? shopAddress,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerAddress,
    required String paymentLabel,
    required bool isPaid,
    required String currencySymbol,
    String? currencyCode,
    required List<VerifiedInvoiceItem> items,
    String subtitle = 'SALES INVOICE',
    String? templateId,
  }) async {
    final effectiveTemplate =
        templateId ?? InvoiceTemplateSettings.currentTemplate.value;
    currencySymbol = safeCurrency(currencySymbol, currencyCode);
    shopName = sanitizeText(shopName);
    shopAddress = sanitizeText(shopAddress ?? '');
    customerName = sanitizeText(customerName);
    customerEmail = sanitizeText(customerEmail);
    customerPhone = sanitizeText(customerPhone);
    customerAddress = sanitizeText(customerAddress);
    paymentLabel = sanitizeText(paymentLabel);
    subtitle = sanitizeText(subtitle);
    items = items
        .map(
          (item) => VerifiedInvoiceItem(
            name: sanitizeText(item.name),
            imei: sanitizeText(item.imei),
            quantity: item.quantity,
            lineTotal: item.lineTotal,
            isVerified: item.isVerified,
          ),
        )
        .toList();

    // Default theme -> keep exact original layout
    if (effectiveTemplate == 'default') {
      return VerifiedInvoicePdf.build(
        fileName: fileName,
        invoiceNumber: invoiceNumber,
        createdAt: createdAt,
        shopName: shopName,
        shopEmail: shopEmail,
        shopPhone: shopPhone,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        paymentLabel: paymentLabel,
        isPaid: isPaid,
        currencySymbol: currencySymbol,
        items: items,
        subtitle: subtitle,
      );
    }

    final totalAmount = items.fold<double>(
      0,
      (sum, item) => sum + (item.quantity * item.lineTotal),
    );

    final pdf = pw.Document();

    // 1. CLASSIC EDITORIAL (Traditional - Ref 1)
    if (effectiveTemplate == 'classic-editorial') {
      const burgundy = PdfColor.fromInt(0xFF800020);
      const ink = PdfColor.fromInt(0xFF1A1A1A);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(
            base: pw.Font.times(),
            bold: pw.Font.timesBold(),
            italic: pw.Font.timesItalic(),
          ),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice no. $invoiceNumber',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 2),
                    pw.Text(_formatDate(createdAt),
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      shopName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: burgundy,
                      ),
                    ),
                    if (shopAddress != null && shopAddress.isNotEmpty)
                      pw.Text(shopAddress,
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(height: 1, color: ink),
            pw.SizedBox(height: 14),
            pw.Text(
              'BILL TO',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: burgundy,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              customerName,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            if (customerPhone.isNotEmpty)
              pw.Text('Phone: $customerPhone',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            pw.Text(
              subtitle,
              style: pw.TextStyle(
                fontSize: 34,
                fontWeight: pw.FontWeight.bold,
                color: burgundy,
                letterSpacing: 2,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: ink, width: 1.5),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 35,
                    child: pw.Text('Qty',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Expanded(
                    child: pw.Text('Item description',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(
                    width: 80,
                    child: pw.Text('Unit price',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(
                    width: 80,
                    child: pw.Text('Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ),
            ...items.map((item) {
              final lineSubtotal = item.quantity * item.lineTotal;
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 35,
                      child: pw.Text('${item.quantity}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.name,
                              style: const pw.TextStyle(fontSize: 9.5)),
                          if (item.imei.isNotEmpty)
                            pw.Text('IMEI: ${item.imei}',
                                style: const pw.TextStyle(
                                    fontSize: 8, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        _fmt(item.lineTotal, currencySymbol),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        _fmt(lineSubtotal, currencySymbol),
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _editorialAmountRow(
                        'Subtotal', totalAmount, currencySymbol),
                    _editorialAmountRow('Total', totalAmount, currencySymbol,
                        bold: true),
                    _editorialAmountRow(
                        'Paid', isPaid ? totalAmount : 0, currencySymbol),
                    _editorialAmountRow('Balance due',
                        isPaid ? 0 : totalAmount, currencySymbol,
                        color: burgundy, bold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: burgundy,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    isPaid ? 'PAID' : 'DUE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('|||| ||| ||||||| ||||',
                        style: const pw.TextStyle(fontSize: 16)),
                    pw.Text(invoiceNumber,
                        style: const pw.TextStyle(
                            fontSize: 7, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Payment: $paymentLabel',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey700)),
                      pw.Text('Thank you',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: burgundy)),
                    ],
                  ),
                  pw.Text('Powered by $shopName',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // 2. WARM MINIMALIST (Traditional - Ref 4)
    else if (effectiveTemplate == 'warm-minimal') {
      const warmCream = PdfColor.fromInt(0xFFFFFDEB);
      const darkBorder = PdfColor.fromInt(0xFF0F172A);
      const limePill = PdfColor.fromInt(0xFFCCFF00);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(24),
              decoration: pw.BoxDecoration(
                color: warmCream,
                border: pw.Border.all(color: darkBorder, width: 1.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          shopName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                            color: darkBorder,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          subtitle,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            letterSpacing: 1.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
                        bottom:
                            pw.BorderSide(color: PdfColors.grey600, width: 0.5),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('DATE ISSUED',
                                  style: pw.TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(_formatDate(createdAt),
                                  style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('INVOICE #',
                                  style: pw.TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(invoiceNumber,
                                  style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('ISSUED TO',
                                  style: pw.TextStyle(
                                      fontSize: 7.5,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(customerName,
                                  style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: darkBorder, width: 1),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.SizedBox(
                          width: 35,
                          child: pw.Text('QTY',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Expanded(
                          child: pw.Text('ITEM / DEVICE',
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(
                          width: 80,
                          child: pw.Text('UNIT PRICE',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.SizedBox(
                          width: 80,
                          child: pw.Text('TOTAL',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  ...items.map((item) {
                    final sub = item.quantity * item.lineTotal;
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 8),
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColors.grey300, width: 0.5),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.SizedBox(
                            width: 35,
                            child: pw.Text('${item.quantity}',
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(item.name,
                                    style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold)),
                                if (item.imei.isNotEmpty)
                                  pw.Text('IMEI: ${item.imei}',
                                      style: const pw.TextStyle(
                                          fontSize: 7.5,
                                          color: PdfColors.grey600)),
                              ],
                            ),
                          ),
                          pw.SizedBox(
                            width: 80,
                            child: pw.Text(
                              _fmt(item.lineTotal, currencySymbol),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.SizedBox(
                            width: 80,
                            child: pw.Text(
                              _fmt(sub, currencySymbol),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  pw.SizedBox(height: 16),
                  pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.SizedBox(
                      width: 200,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Subtotal',
                                  style: const pw.TextStyle(fontSize: 8.5)),
                              pw.Text(_fmt(totalAmount, currencySymbol),
                                  style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: pw.BoxDecoration(
                              color: limePill,
                              borderRadius: pw.BorderRadius.circular(3),
                            ),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Total',
                                    style: pw.TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(_fmt(totalAmount, currencySymbol),
                                    style: pw.TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: pw.FontWeight.bold)),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Balance due',
                                  style: const pw.TextStyle(fontSize: 8.5)),
                              pw.Text(
                                  _fmt(isPaid ? 0 : totalAmount, currencySymbol),
                                  style: const pw.TextStyle(fontSize: 8.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Container(
                    padding: const pw.EdgeInsets.only(top: 14),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        top: pw.BorderSide(color: darkBorder, width: 1),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'THANK YOU!',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text('Powered by $shopName',
                              style: const pw.TextStyle(
                                  fontSize: 8, color: PdfColors.grey600)),
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
    }
    // 3. NEO BOLD (Modern - Ref 2)
    else if (effectiveTemplate == 'neo-bold') {
      const lime = PdfColor.fromInt(0xFFD4FF32);
      const bgLight = PdfColor.fromInt(0xFFFDF4F5);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              color: lime,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(shopName,
                          style: pw.TextStyle(
                              fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text('TECH SOLUTIONS & SALES',
                          style: pw.TextStyle(
                              fontSize: 7, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Text('INVOICE',
                      style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: bgLight,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('INVOICE #',
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text(invoiceNumber,
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER',
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text(customerName,
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DATE',
                          style: const pw.TextStyle(
                              fontSize: 7.5, color: PdfColors.grey600)),
                      pw.Text(_formatDate(createdAt),
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('DESCRIPTION',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(
                        width: 35,
                        child: pw.Text('QTY',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(
                        width: 75,
                        child: pw.Text('UNIT',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.SizedBox(
                        width: 75,
                        child: pw.Text('TOTAL',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey300),
                  ...items.map((item) {
                    final sub = item.quantity * item.lineTotal;
                    return pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(item.name,
                                    style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold)),
                                if (item.imei.isNotEmpty)
                                  pw.Text('Serial: ${item.imei}',
                                      style: const pw.TextStyle(
                                          fontSize: 7.5,
                                          color: PdfColors.grey600)),
                              ],
                            ),
                          ),
                          pw.SizedBox(
                            width: 35,
                            child: pw.Text('${item.quantity}',
                                textAlign: pw.TextAlign.center,
                                style: const pw.TextStyle(fontSize: 8.5)),
                          ),
                          pw.SizedBox(
                            width: 75,
                            child: pw.Text(_fmt(item.lineTotal, currencySymbol),
                                textAlign: pw.TextAlign.right,
                                style: const pw.TextStyle(fontSize: 8.5)),
                          ),
                          pw.SizedBox(
                            width: 75,
                            child: pw.Text(_fmt(sub, currencySymbol),
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lime,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL AMOUNT',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_fmt(totalAmount, currencySymbol),
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    isPaid ? 'STATUS: FULLY PAID' : 'STATUS: PART PAID',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: isPaid ? PdfColors.green800 : PdfColors.orange800,
                    ),
                  ),
                  pw.Text(
                    'Balance: ${_fmt(isPaid ? 0 : totalAmount, currencySymbol)}',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              color: lime,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for shopping with us.',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Powered by $shopName',
                      style: pw.TextStyle(
                          fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // 4. MODERN RETAIL (Modern - Ref 3)
    else if (effectiveTemplate == 'modern-retail') {
      const sage = PdfColor.fromInt(0xFF8EA085);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice',
                        style: pw.TextStyle(
                            fontSize: 28, fontWeight: pw.FontWeight.bold)),
                    pw.Text('No. $invoiceNumber',
                        style: const pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(shopName,
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('SALES | SUPPORT',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text('Invoice to: $customerName',
                style:
                    pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: ${_formatDate(createdAt)}',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 16),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: sage,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('Description',
                        style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  ),
                  pw.SizedBox(
                    width: 35,
                    child: pw.Text('Qty',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  ),
                  pw.SizedBox(
                    width: 75,
                    child: pw.Text('Price',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  ),
                  pw.SizedBox(
                    width: 75,
                    child: pw.Text('Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white)),
                  ),
                ],
              ),
            ),
            ...items.map((item) {
              final sub = item.quantity * item.lineTotal;
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.name,
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          if (item.imei.isNotEmpty)
                            pw.Text('IMEI: ${item.imei}',
                                style: const pw.TextStyle(
                                    fontSize: 7.5, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.SizedBox(
                      width: 35,
                      child: pw.Text('${item.quantity}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.SizedBox(
                      width: 75,
                      child: pw.Text(_fmt(item.lineTotal, currencySymbol),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.SizedBox(
                      width: 75,
                      child: pw.Text(_fmt(sub, currencySymbol),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green700,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    isPaid ? 'PAID' : 'BALANCE DUE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(
                  width: 180,
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total:',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold)),
                          pw.Text(_fmt(totalAmount, currencySymbol),
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Balance due:',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text(
                              _fmt(isPaid ? 0 : totalAmount, currencySymbol),
                              style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('We buy your phone for cash or trade-in.',
                      style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900)),
                  pw.Text('Ask us for a quote at our counter.',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.green800)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // 5. NORDIC SLATE (Modern - Ref 5)
    else {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(shopName,
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Invoice no. $invoiceNumber',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILL TO:',
                        style: const pw.TextStyle(
                            fontSize: 7.5, color: PdfColors.grey600)),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFD9F99D),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        customerName,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromInt(0xFF1A2E05)),
                      ),
                    ),
                  ],
                ),
                pw.Text('INVOICE',
                    style: pw.TextStyle(
                        fontSize: 32,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2)),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice total',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(_fmt(totalAmount, currencySymbol),
                        style: pw.TextStyle(
                            fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Issue date: ${_formatDate(createdAt)}',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('Payment: $paymentLabel',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              color: PdfColor.fromInt(0xFFF1F5F9),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text('Item',
                        style: pw.TextStyle(
                            fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(
                    width: 35,
                    child: pw.Text('Qty',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(
                    width: 75,
                    child: pw.Text('Price',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.SizedBox(
                    width: 75,
                    child: pw.Text('Total',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ),
            ...items.map((item) {
              final sub = item.quantity * item.lineTotal;
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(item.name,
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          if (item.imei.isNotEmpty)
                            pw.Text('IMEI: ${item.imei}',
                                style: const pw.TextStyle(
                                    fontSize: 7.5, color: PdfColors.grey600)),
                        ],
                      ),
                    ),
                    pw.SizedBox(
                      width: 35,
                      child: pw.Text('${item.quantity}',
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.SizedBox(
                      width: 75,
                      child: pw.Text(_fmt(item.lineTotal, currencySymbol),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                    pw.SizedBox(
                      width: 75,
                      child: pw.Text(_fmt(sub, currencySymbol),
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 8.5)),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFD9F99D),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Total: ${_fmt(totalAmount, currencySymbol)}',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF14532D),
                  ),
                ),
              ),
            ),
            pw.Spacer(),
            pw.Text('Thank you for shopping with us.',
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      );
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Builds a Purchase Receipt using the requested or currently preferred template.
  static Future<File> buildPurchaseReceipt({
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
    String? templateId,
  }) async {
    final effectiveTemplate =
        templateId ?? InvoiceTemplateSettings.currentTemplate.value;

    // Default theme -> keep exact original layout
    if (effectiveTemplate == 'default') {
      return PurchaseReceiptPdf.build(
        fileNamePrefix: fileNamePrefix,
        createdAt: createdAt,
        shopName: shopName,
        shopAddress: shopAddress,
        shopPhone: shopPhone,
        shopEmail: shopEmail,
        preparedBy: preparedBy,
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        customerAddress: customerAddress,
        customerIdNumber: customerIdNumber,
        items: items,
        totalAmount: totalAmount,
        currencyCode: currencyCode,
      );
    }

    // Convert InvoicePdfItem to VerifiedInvoiceItem for template reuse
    final mappedItems = items
        .map(
          (item) => VerifiedInvoiceItem(
            name: item.name,
            quantity: item.quantity,
            lineTotal: item.unitPrice,
            imei: item.imeiSerial,
          ),
        )
        .toList();

    return buildSalesInvoice(
      fileName: '${fileNamePrefix}_${createdAt.millisecondsSinceEpoch}.pdf',
      invoiceNumber: 'PR-${createdAt.millisecondsSinceEpoch.toString().substring(5)}',
      createdAt: createdAt,
      shopName: shopName,
      shopEmail: shopEmail,
      shopPhone: shopPhone,
      shopAddress: shopAddress,
      customerName: customerName,
      customerEmail: customerEmail,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      paymentLabel: 'Cash / Transfer',
      isPaid: true,
      currencySymbol: currencyCode,
      currencyCode: currencyCode,
      items: mappedItems,
      subtitle: 'PURCHASE RECEIPT',
      templateId: effectiveTemplate,
    );
  }

  static pw.Widget _editorialAmountRow(
    String label,
    double amount,
    String symbol, {
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            _fmt(amount, symbol),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
  }

  static String _monthName(int m) {
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
      'December'
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return '';
  }

  static String safeCurrency(String symbol, [String? currencyCode]) {
    final code = (currencyCode ?? '').trim().toUpperCase();
    final s = symbol.trim();

    if (code == 'USD' || s == r'$') return r'$';
    if (code == 'GBP' || s == '£') return '£';
    if (code == 'AUD' || s == r'A$') return r'A$';
    if (code == 'CAD' || s == r'C$') return r'C$';
    if (code == 'EUR' || s == '€') return 'EUR ';
    if (code == 'BDT' || s == '৳') return 'BDT ';
    if (code == 'INR' || s == '₹') return 'INR ';
    if (code == 'PKR' || s == '₨') return 'PKR ';
    if (code == 'AED' || s.contains('د.إ')) return 'AED ';
    if (code == 'SAR' || s.contains('﷼')) return 'SAR ';

    final hasHighRune = s.runes.any((r) => r > 255);
    if (hasHighRune) {
      if (code.isNotEmpty && code != 'NONE') return '$code ';
      return '';
    }

    return s.isEmpty ? '' : (s.length > 1 ? '$s ' : s);
  }

  static String sanitizeText(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll('•', '|')
        .replaceAll('·', '|')
        .replaceAll('▪', '-')
        .replaceAll('►', '>')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'");
  }

  static String _fmt(double val, String symbol) {
    final safe = safeCurrency(symbol);
    return '$safe${val.toStringAsFixed(2)}';
  }
}
