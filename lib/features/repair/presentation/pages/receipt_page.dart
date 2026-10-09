import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_outlined_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../../core/utils/invoice_template_settings.dart';
import '../../../invoice/presentation/utils/invoice_template_builder.dart';
import '../../../invoice/presentation/utils/verified_invoice_pdf.dart';
import '../../../invoice/presentation/utils/compact_receipt_pdf.dart';
import '../widgets/dashed_divider.dart';
import '../../../stock/domain/entities/ready_order.dart';
import '../../../../core/utils/invoice_amount.dart';

class ReceiptPage extends StatefulWidget {
  final Map<String, dynamic> repair;

  const ReceiptPage({super.key, this.repair = const {}});

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  bool _isGenerating = false;
  late final ProfileController _profileCtrl;
  String _profileShopName = '';

  @override
  void initState() {
    super.initState();
    _profileCtrl = Get.find<ProfileController>();
    _profileShopName = _profileCtrl.shopName.trim();
    if (_profileShopName.isEmpty) {
      _primeProfileShopName();
    }
  }

  String get _orderId => widget.repair['_id']?.toString() ?? 'N/A';
  String get _deviceModel =>
      widget.repair['deviceModel']?.toString() ?? 'Unknown Device';
  String get _customerName {
    final customerInfo = widget.repair['customerInfo'];
    if (customerInfo is Map) {
      final first = customerInfo['firstName']?.toString() ?? '';
      final last = customerInfo['lastName']?.toString() ?? '';
      final fullName = '$first $last'.trim();
      if (fullName.isNotEmpty) return fullName;

      final directName = customerInfo['name']?.toString().trim() ?? '';
      if (directName.isNotEmpty) return directName;
    }

    final directCustomerName =
        widget.repair['customerName']?.toString().trim() ?? '';
    if (directCustomerName.isNotEmpty) return directCustomerName;

    final first = widget.repair['firstName']?.toString() ?? '';
    final last = widget.repair['lastName']?.toString() ?? '';
    final name = '$first $last'.trim();
    if (name.isNotEmpty) return name;

    final fallbackName = widget.repair['name']?.toString().trim() ?? '';
    if (fallbackName.isNotEmpty) return fallbackName;

    return 'Customer';
  }

  String get _shopName {
    final repairShopName = widget.repair['shopName']?.toString().trim() ?? '';
    if (repairShopName.isNotEmpty) return repairShopName;
    if (_profileShopName.isNotEmpty) return _profileShopName;
    return 'Your Shop';
  }

  double get _price => ReadyOrder.totalPrice(widget.repair);

  String get _date {
    final parsed = DateTime.tryParse(
      widget.repair['createdAt']?.toString() ?? '',
    );
    if (parsed == null) return 'N/A';
    final local = parsed.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[local.month - 1]} ${local.day.toString().padLeft(2, '0')}, ${local.year}';
  }

  String get _time {
    final parsed = DateTime.tryParse(
      widget.repair['createdAt']?.toString() ?? '',
    );
    if (parsed == null) return 'N/A';
    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get _invoiceNumber {
    final id = _orderId;
    final short = id.length > 6
        ? id.substring(id.length - 6).toUpperCase()
        : id.toUpperCase();
    return 'IMS-$short';
  }

  String get _email {
    final customerInfo = widget.repair['customerInfo'];
    if (customerInfo is Map) {
      final customerEmail = customerInfo['email']?.toString().trim() ?? '';
      if (customerEmail.isNotEmpty) return customerEmail;
    }
    return widget.repair['email']?.toString() ?? 'N/A';
  }

  Future<void> _primeProfileShopName() async {
    await _profileCtrl.fetchProfile();
    if (!mounted) return;
    setState(() {
      _profileShopName = _profileCtrl.shopName.trim();
    });
  }

  String get _customerPhone => widget.repair['phoneNumber']?.toString() ?? '';
  double get _paid =>
      (widget.repair['status'] == 'collected'
              ? _price
              : ReadyOrder.depositPaid(widget.repair))
          .clamp(0, _price)
          .toDouble();
  List<VerifiedInvoiceItem> get _receiptItems => [
    VerifiedInvoiceItem(
      name: '$_deviceModel repair',
      imei: widget.repair['IMEINumber']?.toString() ?? '',
      quantity: 1,
      lineTotal: _price,
    ),
  ];
  CompactReceiptData get _compactReceipt => CompactReceiptData(
    reference: _invoiceNumber,
    shopName: _shopName,
    shopAddress: _profileCtrl.shopAddress,
    shopPhone: _profileCtrl.phone,
    customerName: _customerName,
    customerPhone: _customerPhone,
    customerEmail: _email,
    currencyCode: _profileCtrl.currencyCode,
    date: DateTime.tryParse(
      widget.repair['createdAt']?.toString() ?? '',
    )?.toLocal(),
    title: 'Repair Receipt',
    items: _receiptItems,
    total: _price,
    paid: _paid,
    due: invoiceMoney(_price - _paid),
    trackingUrl: _qrData,
    servedBy: _profileCtrl.servedBy,
  );

  Future<void> _printReceipt() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final bytes = await CompactReceiptPdf.build(_compactReceipt);
      await Printing.layoutPdf(
        name: _invoiceNumber,
        format: PdfPageFormat.roll80,
        dynamicLayout: false,
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not print receipt')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateAndSharePdf() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final file = await InvoiceTemplateBuilder.buildSalesInvoice(
        fileName: '$_invoiceNumber.pdf',
        invoiceNumber: _invoiceNumber,
        createdAt:
            DateTime.tryParse(widget.repair['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        templateId: InvoiceTemplateSettings.activeId,
        shopName: _shopName,
        shopEmail: _profileCtrl.email,
        shopPhone: _profileCtrl.phone,
        shopAddress: _profileCtrl.shopAddress,
        customerName: _customerName,
        customerEmail: _email,
        customerPhone: _customerPhone,
        customerAddress: '',
        subtitle: 'REPAIR RECEIPT',
        paymentLabel: widget.repair['paymentMethod']?.toString() ?? '',
        isPaid: _paid >= _price,
        amountPaid: _paid,
        currencySymbol: _profileCtrl.currencySymbol,
        currencyCode: _profileCtrl.currencyCode,
        items: _receiptItems,
        trackingUrl: _qrData,
        servedBy: _profileCtrl.servedBy,
      );
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Repair receipt $_invoiceNumber',
        text: 'Track your repair: $_qrData',
        sharePositionOrigin: box == null
            ? const Rect.fromLTWH(0, 0, 1, 1)
            : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate receipt')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _formatCurrency(double value) {
    return '${_profileCtrl.currencySymbol}${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppOutlinedButton(
                  label: _isGenerating ? 'Generating...' : 'Get PDF Receipt',
                  onPressed: _isGenerating ? null : _generateAndSharePdf,
                ),
                const SizedBox(height: 8),
                AppOutlinedButton(
                  label: 'Print Receipt · 80 mm',
                  onPressed: _isGenerating ? null : _printReceipt,
                ),
              ],
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
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }
}
