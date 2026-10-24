import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/commerce_events.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/invoice_template_settings.dart';
import '../../../../core/utils/invoice_amount.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../customer/domain/entities/outstanding_invoice.dart';
import '../../../customer/presentation/widgets/balance_payment_sheet.dart';
import '../../../customer/data/repositories/customer_repository_impl.dart';
import '../../../invoice/presentation/utils/invoice_template_builder.dart';
import '../../../invoice/presentation/utils/verified_invoice_pdf.dart';
import '../../../invoice/presentation/utils/compact_receipt_pdf.dart';
import '../../../invoice/presentation/widgets/invoice_delivery_actions.dart';
import '../../../invoice/presentation/widgets/score_plus_logo.dart';
import '../../../profile/presentation/controller/profile_controller.dart';

/// Records a confirmed cash/card payment through the existing invoice API.
Future<bool> recordCheckoutPayment(
  BuildContext context, {
  required List<VerifiedInvoiceItem> items,
  List<Map<String, dynamic>> stockLines = const [],
  List<String> repairIds = const [],
  Customer? customer,
  VoidCallback? onRecorded,
  ApiClient? apiClient,
  String customerName = '',
  String customerEmail = '',
  String customerPhone = '',
}) async {
  if (repairIds.length > 1) {
    showErrorSnackbar(
      'Collect one repair per payment. The current API supports one repair per invoice.',
    );
    return false;
  }
  final total = invoiceMoney(
    items.fold<double>(0, (sum, line) => sum + invoiceMoney(line.lineTotal)),
  );
  if (!total.isFinite ||
      total < 0 ||
      items.any(
        (i) => i.quantity <= 0 || !i.lineTotal.isFinite || i.lineTotal < 0,
      )) {
    showErrorSnackbar('Check item quantities and prices');
    return false;
  }
  final method = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Choose payment method'),
            subtitle: Text('Confirm only after receiving payment.'),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Cash'),
            onTap: () => Navigator.pop(ctx, 'cash'),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Card'),
            subtitle: const Text(
              'Record a payment received on your card terminal',
            ),
            onTap: () => Navigator.pop(ctx, 'card'),
          ),
        ],
      ),
    ),
  );
  if (method == null || !context.mounted) return false;
  final profile = Get.find<ProfileController>();
  bool recorded = false;
  final api = apiClient ?? ApiClient(baseUrl);
  try {
    if (profile.userId.isEmpty) await profile.fetchProfile();
    if (profile.userId.isEmpty) {
      throw const FormatException('Shop profile is unavailable');
    }
    var invoiceCustomer = customer;
    if (invoiceCustomer == null && customerName.trim().isNotEmpty) {
      final customers = CustomerRepositoryImpl(api);
      final saved = await customers.getCustomers(profile.userId);
      final email = customerEmail.trim().toLowerCase();
      final phone = customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
      for (final candidate in saved) {
        if ((email.isNotEmpty && candidate.email.toLowerCase() == email) ||
            (phone.isNotEmpty &&
                candidate.phone.replaceAll(RegExp(r'[^0-9]'), '') == phone)) {
          invoiceCustomer = candidate;
          break;
        }
      }
    }
    if (!context.mounted) return false;
    final oldInvoices = invoiceCustomer == null
        ? <OutstandingInvoice>[]
        : await chooseBalancePayment(
            context,
            api: api,
            customerId: invoiceCustomer.id,
            today: total,
            currencyCode: profile.currencyCode,
            currencySymbol: profile.currencySymbol,
          );
    if (oldInvoices == null || !context.mounted) return false;
    final paymentTotal =
        ((total +
                    oldInvoices.fold<double>(
                      0,
                      (sum, invoice) => sum + invoice.due,
                    )) *
                100)
            .round() /
        100;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Record ${profile.currencySymbol}${paymentTotal.toStringAsFixed(2)} by $method?',
        ),
        content: const Text(
          'Confirm that payment has been received. This will save today\'s invoice, settle any selected previous invoices and complete collection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Payment received'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    if (invoiceCustomer == null && customerName.trim().isNotEmpty) {
      invoiceCustomer = await CustomerRepositoryImpl(api).createCustomer(
        firstName: customerName.trim(),
        email: customerEmail,
        phone: customerPhone,
      );
    }

    final now = DateTime.now();
    final number = 'INV-${now.microsecondsSinceEpoch}';
    final tracking = repairIds.isEmpty
        ? ''
        : 'https://imoscan.com/my-invoice/${Uri.encodeComponent(repairIds.single)}';
    final pdf = await InvoiceTemplateBuilder.buildSalesInvoice(
      fileName: '$number.pdf',
      invoiceNumber: number,
      createdAt: now,
      templateId: InvoiceTemplateSettings.activeId,
      shopName: profile.shopName,
      shopEmail: profile.email,
      shopPhone: profile.phone,
      shopAddress: profile.shopAddress,
      customerName: invoiceCustomer?.fullName ?? customerName,
      customerEmail: invoiceCustomer?.email ?? customerEmail,
      customerPhone: invoiceCustomer?.phone ?? customerPhone,
      customerAddress: invoiceCustomer?.address ?? '',
      paymentLabel: method,
      isPaid: true,
      currencySymbol: profile.currencySymbol,
      currencyCode: profile.currencyCode,
      items: [
        ...items,
        for (final invoice in oldInvoices)
          VerifiedInvoiceItem(
            name: 'Previous balance payment: ${invoice.reference}',
            quantity: 1,
            lineTotal: invoice.due,
          ),
      ],
      trackingUrl: tracking,
      servedBy: profile.servedBy,
    );
    final payload = FormData.fromMap({
      'shopkeeperId': profile.userId,
      'type': repairIds.isEmpty ? 'Custom invoice' : 'repair',
      'invoiceNumber': number,
      'invoiceTemplate': InvoiceTemplateSettings.activeId,
      'totalAmount': total,
      'amountPaid': total,
      'dueAmount': 0,
      'paymentStatus': 'paid',
      'paymentMethod': method,
      'currency': profile.currencyCode,
      if (oldInvoices.isNotEmpty)
        'allocations': jsonEncode([
          for (final invoice in oldInvoices)
            {'invoiceId': invoice.id, 'amountApplied': invoice.due},
        ]),
      if (invoiceCustomer != null) 'customerInfo': invoiceCustomer.id,
      if (repairIds.isNotEmpty) 'repairRequestId': repairIds.single,
      'lineItems': jsonEncode(stockLines),
      if (stockLines.isNotEmpty)
        'itemsIds': stockLines.map((l) => l['itemId']).toList(),
      'invoice': await MultipartFile.fromFile(
        pdf.path,
        filename: '$number.pdf',
      ),
    });
    final res = await api.post(InvoiceEndpoints.create, data: payload);
    final data = res.data['data'];
    if (data is! Map || data['_id'] == null) {
      throw const FormatException('Invoice confirmation is missing');
    }
    recorded = true;
    onRecorded?.call();
    CommerceEvents.changed();
    if (!context.mounted) return true;
    final file = data['invoice'];
    final pdfUrl = file is Map ? file['url']?.toString() : null;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text('Payment recorded · $number')),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Email'),
                onTap: () => showInvoiceEmailSheet(
                  ctx,
                  invoiceRef: number,
                  pdfUrl: pdfUrl,
                  amountLabel:
                      '${profile.currencySymbol}${paymentTotal.toStringAsFixed(2)}',
                  customerId: invoiceCustomer?.id ?? '',
                  customerEmail: invoiceCustomer?.email ?? customerEmail,
                  trackingUrl: tracking,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: const Text('WhatsApp'),
                subtitle: const Text('Choose WhatsApp in the share sheet'),
                onTap: () => shareInvoiceOnWhatsApp(
                  ctx,
                  pdfUrl: pdfUrl,
                  invoiceRef: number,
                  trackingUrl: tracking,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.sms_outlined),
                title: const Text('SMS'),
                onTap: () => sendInvoiceMessage(
                  ctx,
                  pdfUrl: pdfUrl,
                  invoiceRef: number,
                  customerPhone: invoiceCustomer?.phone ?? customerPhone,
                  shopName: profile.shopName,
                  trackingUrl: tracking,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.print_outlined),
                title: const Text('Print'),
                onTap: () => printOriginalInvoicePdf(
                  ctx,
                  pdfUrl: pdfUrl,
                  invoiceRef: number,
                  receipt: CompactReceiptData(
                    reference: number,
                    shopName: profile.shopName,
                    shopAddress: profile.shopAddress,
                    shopPhone: profile.phone,
                    customerName: invoiceCustomer?.fullName ?? customerName,
                    customerEmail: invoiceCustomer?.email ?? customerEmail,
                    customerPhone: invoiceCustomer?.phone ?? customerPhone,
                    currencyCode: profile.currencyCode,
                    paymentMethod: method,
                    servedBy: profile.servedBy,
                    trackingUrl: tracking,
                    date: now,
                    total: paymentTotal,
                    paid: paymentTotal,
                    due: 0,
                    items: [
                      ...items,
                      for (final invoice in oldInvoices)
                        VerifiedInvoiceItem(
                          name:
                              'Previous balance payment: ${invoice.reference}',
                          quantity: 1,
                          lineTotal: invoice.due,
                        ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const ScorePlusLogo(),
                title: const Text('Score+'),
                onTap: () => showScorePlus(
                  ctx,
                  invoiceId: data['_id'].toString(),
                  email: invoiceCustomer?.email ?? customerEmail,
                  phone: invoiceCustomer?.phone ?? customerPhone,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
    return true;
  } on DioException catch (e) {
    if (recorded) return true;
    showErrorSnackbar(
      e.response?.data?['message']?.toString() ??
          'Payment was not confirmed. Check invoice history before trying again.',
    );
  } catch (_) {
    if (recorded) return true;
    showErrorSnackbar(
      'Payment was not confirmed. Check invoice history before trying again.',
    );
  }
  return recorded;
}
