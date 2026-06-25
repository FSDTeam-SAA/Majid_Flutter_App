import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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

  Future<void> _generateAndSharePdf() async {
    setState(() => _isGenerating = true);
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'REPAIR RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    _shopName,
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 16),
                _pdfRow('Order ID', _orderId),
                _pdfRow('Date', _date),
                _pdfRow('Time', _time),
                _pdfRow('Status', _status),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Customer Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfRow('Name', _customerName),
                _pdfRow('Email',
                    widget.repair['email']?.toString() ?? 'N/A'),
                _pdfRow('Phone',
                    widget.repair['phoneNumber']?.toString() ?? 'N/A'),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Repair Details',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfRow('Device', _deviceModel),
                _pdfRow('Description',
                    widget.repair['description']?.toString() ??
                        'No description'),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Price',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      _formatCurrency(_price),
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final fileName = 'receipt_${_orderId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      try {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Repair Receipt - $_deviceModel',
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

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
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

  Widget _buildQrCode() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/qrcode.jpg',
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
