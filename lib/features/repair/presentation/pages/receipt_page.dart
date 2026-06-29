import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_outlined_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../widgets/dashed_divider.dart';

class ReceiptPage extends StatefulWidget {
  final Map<String, dynamic> repair;

  const ReceiptPage({super.key, this.repair = const {}});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _isGenerating = false;

  String get _orderId => widget.repair['_id']?.toString() ?? 'N/A';
  String get _deviceModel =>
      widget.repair['deviceModel']?.toString() ?? 'Unknown Device';
  String get _customerName {
    final first = widget.repair['firstName']?.toString() ?? '';
    final last = widget.repair['lastName']?.toString() ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Customer' : name;
  }

  String get _shopName =>
      widget.repair['shopName']?.toString() ?? 'Your Shop';

  double get _price =>
      (widget.repair['price'] as num?)?.toDouble() ?? 0;

  String get _date {
    final parsed = DateTime.tryParse(
        widget.repair['createdAt']?.toString() ?? '');
    if (parsed == null) return 'N/A';
    final local = parsed.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[local.month - 1]} ${local.day.toString().padLeft(2, '0')}, ${local.year}';
  }

  String get _time {
    final parsed = DateTime.tryParse(
        widget.repair['createdAt']?.toString() ?? '');
    if (parsed == null) return 'N/A';
    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get _status =>
      widget.repair['status']?.toString().toUpperCase() ?? 'COMPLETED';

  String get _invoiceNumber {
    final id = _orderId;
    final short = id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase();
    return 'IMS-$short';
  }

  String get _email => widget.repair['email']?.toString() ?? 'N/A';
  String get _techFeedback => widget.repair['technicianFeedback']?.toString() ?? '';

  List<Map<String, String>> get _techNotes {
    final notes = widget.repair['technicianNotes'];
    if (notes is! List || notes.isEmpty) return [];
    return notes.whereType<Map>().map((n) {
      return {
        'part': n['partName']?.toString() ?? '-',
        'cost': '\$${(n['cost'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
        'time': '${n['time']?.toString() ?? '-'}h',
      };
    }).toList();
  }

  Future<void> _generateAndSharePdf() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = pw.Document();
      final green = PdfColor.fromHex('#4CAF50');
      final darkText = PdfColors.grey900;
      final lightText = PdfColors.grey600;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── Green header ──
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.fromLTRB(40, 36, 40, 28),
                  color: green,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Repair Invoice', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                          pw.SizedBox(height: 4),
                          pw.Text('Verified Device Repair Invoice', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#C8E6C9'))),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(6)),
                        child: pw.Text('✓  VERIFIED', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: green)),
                      ),
                    ],
                  ),
                ),

                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 24),

                      // ── Invoice no & date ──
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                              pw.Text('INVOICE NO', style: pw.TextStyle(fontSize: 9, color: lightText, letterSpacing: 1)),
                              pw.SizedBox(height: 4),
                              pw.Text(_invoiceNumber, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkText)),
                            ]),
                            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                              pw.Text('DATE', style: pw.TextStyle(fontSize: 9, color: lightText, letterSpacing: 1)),
                              pw.SizedBox(height: 4),
                              pw.Text(_date, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkText)),
                            ]),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 20),

                      // ── Device info box ──
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5'), borderRadius: pw.BorderRadius.circular(8)),
                        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text(_deviceModel, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: darkText)),
                          if (widget.repair['IMEINumber'] != null) ...[
                            pw.SizedBox(height: 4),
                            pw.Text('IMEI: ${widget.repair['IMEINumber']}', style: pw.TextStyle(fontSize: 11, color: lightText)),
                          ],
                          pw.SizedBox(height: 4),
                          pw.Text('Status: $_status', style: pw.TextStyle(fontSize: 11, color: lightText)),
                        ]),
                      ),
                      pw.SizedBox(height: 20),

                      // ── Customer & Shop side by side ──
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(child: _pdfInfoBox('CUSTOMER', _customerName, _email)),
                          pw.SizedBox(width: 16),
                          pw.Expanded(child: _pdfInfoBox('REPAIR SHOP', _shopName, 'Created: $_date')),
                        ],
                      ),
                      pw.SizedBox(height: 24),

                      // ── Repair notes table ──
                      _buildNotesTable(),
                      pw.SizedBox(height: 20),

                      // ── Technician feedback & totals row ──
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(14),
                              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
                              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                pw.Text('TECHNICIAN FEEDBACK', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: darkText, letterSpacing: 1)),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  _techFeedback.isNotEmpty ? _techFeedback : 'No feedback provided yet.',
                                  style: pw.TextStyle(fontSize: 10, color: lightText, lineSpacing: 4),
                                ),
                              ]),
                            ),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Container(
                            width: 140,
                            padding: const pw.EdgeInsets.all(14),
                            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)),
                            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                              _pdfTotalLine('Subtotal', _formatCurrency(_price)),
                              pw.SizedBox(height: 6),
                              _pdfTotalLine('Tax', _formatCurrency(0)),
                              pw.Divider(color: PdfColors.grey400),
                              pw.SizedBox(height: 2),
                              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                                pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText)),
                                pw.Text(_formatCurrency(_price), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText)),
                              ]),
                            ]),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 24),

                      // ── QR code ──
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: _qrData,
                        width: 80,
                        height: 80,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Scan to verify invoice', style: pw.TextStyle(fontSize: 9, color: lightText)),
                      pw.SizedBox(height: 20),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 10),

                      // ── Footer ──
                      pw.Center(
                        child: pw.Column(children: [
                          pw.Text('Thank you for choosing $_shopName', style: pw.TextStyle(fontSize: 10, color: lightText)),
                          pw.SizedBox(height: 2),
                          pw.Text('Computer generated smart verified invoice', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName = 'repair_invoice_${_invoiceNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Repair Invoice - $_deviceModel',
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved: ${file.path}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  pw.Widget _pdfInfoBox(String title, String name, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500, letterSpacing: 1)),
        pw.SizedBox(height: 6),
        pw.Text(name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 3),
        pw.Text(subtitle, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
      ]),
    );
  }

  pw.Widget _buildNotesTable() {
    final green = PdfColor.fromHex('#4CAF50');
    final notes = _techNotes;

    final rows = notes.isEmpty
        ? [['−', 'No Repair Notes Added', '−', _formatCurrency(0)]]
        : notes.map((n) => ['-', n['part']!, n['time']!, n['cost']!]).toList();

    return pw.TableHelper.fromTextArray(
      headerDecoration: pw.BoxDecoration(color: green),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      cellStyle: pw.TextStyle(fontSize: 10),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      headers: ['DATE', 'DESCRIPTION', 'TIME', 'COST'],
      data: rows,
    );
  }

  pw.Widget _pdfTotalLine(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  String _formatCurrency(double value) {
    return '£${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Order ID', _orderId),
      ('Date', _date),
      ('Time', _time),
      ('Shop Name', _shopName),
      ('Device', _deviceModel),
      ('Customer', _customerName),
      ('Price', _formatCurrency(_price)),
    ];

    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Receipt'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(height: 30),
                  _buildVerifiedIcon(),
                  SizedBox(height: 16),
                  Text(
                    'Receipt Verified',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildDetails(rows),
                  SizedBox(height: 20),
                  _buildQrCode(),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 28),
            child: AppOutlinedButton(
              label: _isGenerating ? 'Generating...' : 'Get PDF Receipt',
              onPressed: _isGenerating ? null : _generateAndSharePdf,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedIcon() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.15),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: AppColors.primary,
        size: 42,
      ),
    );
  }

  Widget _buildDetails(List<(String, String)> rows) {
    return Column(
      children: rows.asMap().entries.map((e) {
        final isFirst = e.key == 0;
        final isLast = e.key == rows.length - 1;
        return Column(
          children: [
            if (isFirst)
              Divider(color: AppColors.fieldBorder, height: 1, thickness: 1),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.value.$1,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      e.value.$2,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight:
                            e.value.$1 == 'Shop Name' || e.value.$1 == 'Price'
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              DashedDivider()
            else
              Divider(color: AppColors.fieldBorder, height: 1, thickness: 1),
          ],
        );
      }).toList(),
    );
  }

  String get _qrData {
    final id = widget.repair['_id']?.toString() ?? '';
    return 'http://187.77.187.56:4897/my-invoice/$id';
  }

  Widget _buildQrCode() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: QrImageView(
        data: _qrData,
        version: QrVersions.auto,
        size: 220,
        backgroundColor: Colors.white,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}
