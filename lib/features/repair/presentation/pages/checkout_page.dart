import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../invoice/presentation/utils/invoice_pdf_builder.dart';
import '../../../profile/presentation/controller/profile_controller.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> repair;

  const CheckoutPage({super.key, this.repair = const {}});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final ApiClient _api;
  bool _ordersExpanded = false;
  bool _isSending = false;
  // A getter, not a field: captured at construction this read the
  // GBP fallback before the profile had loaded and never updated.
  String get _currencySymbol => Get.find<ProfileController>().currencySymbol;

  Map<String, dynamic> get _repair => widget.repair;

  String get _deviceModel =>
      _repair['deviceModel']?.toString() ?? 'Unknown Device';
  String get _requestId => _repair['_id']?.toString() ?? 'N/A';
  double get _price => (_repair['price'] as num?)?.toDouble() ?? 0;
  double get _depositPaid => (_repair['depositPaid'] as num?)?.toDouble() ?? 0;
  double get _discount => (_repair['discount'] as num?)?.toDouble() ?? 0;
  double get _totalCost {
    final subtotal = _price - _depositPaid;
    if (_discount > 0) {
      return subtotal * (1 - _discount / 100);
    }
    return subtotal;
  }

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
  }

  Future<void> _sendInvoice() async {
    final repairId = _repair['_id']?.toString();
    if (repairId == null || repairId.isEmpty) {
      _showMessage('Invalid repair request');
      return;
    }

    setState(() => _isSending = true);
    try {
      final now = DateTime.now();
      final pdfFile = await InvoicePdfBuilder.build(
        fileNamePrefix: 'repair_invoice',
        invoiceTitle: 'REPAIR INVOICE',
        invoiceNumber: repairId,
        createdAt: now,
        shopName: _repair['shopName']?.toString() ?? 'Your Shop',
        shopAddress: _repair['shopAddress']?.toString() ?? '',
        shopEmail: _repair['shopEmail']?.toString() ?? '',
        shopPhone: _repair['shopPhone']?.toString() ?? '',
        customerName: [
          _repair['firstName']?.toString() ?? '',
          _repair['lastName']?.toString() ?? '',
        ].where((value) => value.isNotEmpty).join(' '),
        customerEmail: _repair['email']?.toString() ?? '',
        customerPhone:
            _repair['phoneNumber']?.toString() ??
            _repair['phone']?.toString() ??
            '',
        customerAddress:
            _repair['address']?.toString() ??
            _repair['billingAddress']?.toString() ??
            '',
        paymentType: _repair['paymentType']?.toString() ?? 'cash',
        currencySymbol: _currencySymbol,
        items: [
          InvoicePdfItem(
            name: _deviceModel,
            code: _requestId,
            quantity: 1,
            unitPrice: _price,
          ),
        ],
        totalAmount: _totalCost,
        footerNote: 'Generated from iMoScan checkout flow.',
      );
      final shopkeeperId = (_repair['shopkeeperId'] ?? _repair['userId'] ?? '')
          .toString();
      final customerId = (_repair['customerId'] ?? '').toString();
      final payload = FormData();
      payload.fields.addAll([
        MapEntry('shopkeeperId', shopkeeperId),
        MapEntry('type', 'repair'),
        MapEntry('repairRequestId', repairId),
        MapEntry('totalAmount', _totalCost.toString()),
        MapEntry('paymentMethod', _repair['paymentType']?.toString() ?? 'cash'),
        if (customerId.isNotEmpty) MapEntry('customerInfo', customerId),
      ]);
      payload.files.add(
        MapEntry(
          'invoice',
          await MultipartFile.fromFile(
            pdfFile.path,
            filename: pdfFile.uri.pathSegments.last,
          ),
        ),
      );

      await _api.post(InvoiceEndpoints.create, data: payload);
      if (!mounted) return;
      _showMessage('Invoice sent successfully!');
      Navigator.pop(context, true);
    } on DioException catch (e) {
      _showMessage(e.response?.data?['message'] ?? 'Failed to send invoice');
    } catch (e) {
      _showMessage('Failed to send invoice');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'Check Out',
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 14),
                  _buildOrdersDropdown(),
                  SizedBox(height: 20),
                  Text(
                    'Products',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildProductItem(),
                  SizedBox(height: 24),
                  _buildSummary(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: AppButton(
              label: _isSending ? 'Sending...' : 'Send Invoice',
              onPressed: _isSending ? null : _sendInvoice,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersDropdown() {
    return GestureDetector(
      onTap: () => setState(() => _ordersExpanded = !_ordersExpanded),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repair Details',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      _deviceModel,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Icon(
                  _ordersExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if (_ordersExpanded) ...[
              Divider(color: AppColors.fieldBorder, height: 20),
              _detailRow('Request ID', '#$_requestId'),
              _detailRow('Customer', _repair['firstName']?.toString() ?? 'N/A'),
              _detailRow(
                'Status',
                _repair['status']?.toString().toUpperCase() ?? 'IN PROGRESS',
              ),
              _detailRow(
                'Description',
                _repair['description']?.toString() ?? 'N/A',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem() {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.phone_iphone,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _deviceModel,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'REQ-$_requestId',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(_price),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        _summaryRow('Repair Cost', _formatCurrency(_price)),
        if (_depositPaid > 0)
          _summaryRow('Deposit Paid', _formatCurrency(_depositPaid)),
        if (_discount > 0) _summaryRow('Discount', '-${_discount.toInt()}%'),
        Divider(color: AppColors.fieldBorder, height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Cost',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatCurrency(_totalCost),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Column(
      children: [
        Divider(color: AppColors.fieldBorder, height: 1),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                value,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    return '$_currencySymbol${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}
