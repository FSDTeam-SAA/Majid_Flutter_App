import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.Widget invoiceTrackingFooter({
  String trackingUrl = '',
  String servedBy = '',
  String paymentSummary = '',
}) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 8),
  child: pw.Row(
    children: [
      if (trackingUrl.isNotEmpty) ...[
        pw.BarcodeWidget(
          barcode: pw.Barcode.qrCode(),
          data: trackingUrl,
          width: 40,
          height: 40,
        ),
        pw.SizedBox(width: 10),
      ],
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (paymentSummary.isNotEmpty)
              pw.Text(paymentSummary, style: const pw.TextStyle(fontSize: 8)),
            if (servedBy.isNotEmpty)
              pw.Text(
                'Served by: $servedBy',
                style: const pw.TextStyle(fontSize: 8),
              ),
            if (trackingUrl.isNotEmpty)
              pw.UrlLink(
                destination: trackingUrl,
                child: pw.Text(
                  'Track your repair: $trackingUrl',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.blue),
                ),
              ),
          ],
        ),
      ),
    ],
  ),
);
