import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/invoice.dart';
import 'verified_invoice_pdf.dart';

class CompactReceiptData {
  const CompactReceiptData({
    required this.reference,
    required this.shopName,
    this.title = 'Receipt',
    this.shopAddress = '',
    this.shopPhone = '',
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.currencyCode = 'GBP',
    this.paymentMethod = '',
    this.servedBy = '',
    this.trackingUrl = '',
    this.date,
    this.total,
    this.paid,
    this.due,
    this.items = const [],
  });
  final String reference, shopName, title, shopAddress, shopPhone;
  final String customerName,
      customerPhone,
      customerEmail,
      currencyCode,
      paymentMethod,
      servedBy,
      trackingUrl;
  final DateTime? date;
  final double? total, paid, due;
  final List<VerifiedInvoiceItem> items;

  factory CompactReceiptData.fromInvoice(
    Invoice invoice, {
    required String shopName,
    String shopAddress = '',
    String shopPhone = '',
    String currencyCode = 'GBP',
  }) => CompactReceiptData(
    reference: invoice.reference,
    shopName: shopName,
    shopAddress: shopAddress,
    shopPhone: shopPhone,
    title: invoice.isPurchase ? 'Purchase Receipt' : 'Receipt',
    customerName: invoice.customerName,
    customerEmail: invoice.customerEmail ?? '',
    customerPhone: invoice.customerPhone ?? '',
    currencyCode: invoice.currency ?? currencyCode,
    paymentMethod: invoice.paymentMethod ?? '',
    servedBy: invoice.servedBy,
    trackingUrl: invoice.trackingUrl,
    date: DateTime.tryParse(invoice.createdAt ?? '')?.toLocal(),
    total: invoice.totalAmount,
    paid:
        invoice.amountPaid ??
        (invoice.paymentStatus == 'paid' ? invoice.totalAmount : null),
    due:
        invoice.dueAmount ??
        (invoice.totalAmount != null && invoice.amountPaid != null
            ? (invoice.totalAmount! - invoice.amountPaid!)
                  .clamp(0, double.infinity)
                  .toDouble()
            : null),
  );
}

abstract final class CompactReceiptPdf {
  static Future<Uint8List> build(CompactReceiptData data) async {
    for (final amount in [
      data.total,
      data.paid,
      data.due,
      ...data.items.map((item) => item.lineTotal),
    ]) {
      if (amount != null && (!amount.isFinite || amount < 0)) {
        throw const FormatException('Invalid receipt amount');
      }
    }
    final pdf = pw.Document();
    String money(double value) =>
        '${data.currencyCode} ${value.toStringAsFixed(2)}';
    pw.Widget row(String label, String value, {bool bold = false}) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: pw.Text(label)),
              pw.SizedBox(width: 8),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ],
          ),
        );
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ).copyWith(defaultTextStyle: const pw.TextStyle(fontSize: 9)),
        build: (_) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              data.shopName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            if (data.shopAddress.isNotEmpty)
              pw.Text(data.shopAddress, textAlign: pw.TextAlign.center),
            if (data.shopPhone.isNotEmpty)
              pw.Text(data.shopPhone, textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 8),
            pw.Text(
              data.title.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(data.reference, textAlign: pw.TextAlign.center),
            if (data.date != null)
              pw.Text(
                '${data.date!.day}/${data.date!.month}/${data.date!.year} ${data.date!.hour.toString().padLeft(2, '0')}:${data.date!.minute.toString().padLeft(2, '0')}',
                textAlign: pw.TextAlign.center,
              ),
            pw.Divider(),
            if (data.customerName.isNotEmpty)
              pw.Text('Customer: ${data.customerName}'),
            if (data.customerPhone.isNotEmpty) pw.Text(data.customerPhone),
            if (data.customerEmail.isNotEmpty) pw.Text(data.customerEmail),
            if (data.items.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text(
                  'Payment summary. Refer to the invoice for item details.',
                ),
              ),
            for (final item in data.items) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                item.name,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              if (item.imei.isNotEmpty) pw.Text('IMEI/Serial: ${item.imei}'),
              row('Quantity: ${item.quantity}', money(item.lineTotal)),
            ],
            pw.Divider(),
            if (data.total != null)
              row('Total', money(data.total!), bold: true),
            if (data.paid != null)
              row(
                data.title == 'Purchase Receipt' ? 'Paid to customer' : 'Paid',
                money(data.paid!),
                bold: true,
              ),
            if (data.due != null) row('Balance due', money(data.due!)),
            if (data.paymentMethod.isNotEmpty)
              pw.Text('Payment: ${data.paymentMethod}'),
            if (data.servedBy.isNotEmpty)
              pw.Text('Served by: ${data.servedBy}'),
            if (data.trackingUrl.isNotEmpty) ...[
              pw.Divider(),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: data.trackingUrl,
                  width: 60,
                  height: 60,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.UrlLink(
                destination: data.trackingUrl,
                child: pw.Text(
                  data.trackingUrl,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ),
            ],
            pw.SizedBox(height: 10),
            pw.Text(
              'Thank you. Please keep this receipt.',
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }
}
