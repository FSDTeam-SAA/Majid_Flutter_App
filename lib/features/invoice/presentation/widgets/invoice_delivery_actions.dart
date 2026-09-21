import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart'
    show baseUrl, CustomerEndpoints, InvoiceEndpoints;
import '../../../../core/utils/colors.dart';
import '../../../transactions/presentation/widgets/transaction_colors.dart';

bool _hasPdf(String? url) {
  final uri = Uri.tryParse(url ?? '');
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

String _pdfName(String invoiceRef) {
  final safeRef = invoiceRef.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  return '${safeRef.isEmpty ? 'invoice' : safeRef}.pdf';
}

Rect _shareOrigin(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }
  return const Rect.fromLTWH(0, 0, 1, 1);
}

Future<XFile> _originalPdf(String url, String invoiceRef) async {
  final response = await Dio().get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes),
  );
  final bytes = response.data;
  if (bytes == null || bytes.isEmpty) {
    throw const FormatException('Invoice PDF is empty');
  }
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/${_pdfName(invoiceRef)}');
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, mimeType: 'application/pdf');
}

Future<void> openOriginalInvoicePdf(
  BuildContext context, {
  required String? pdfUrl,
}) async {
  if (!_hasPdf(pdfUrl)) {
    _showMessage(context, 'Original invoice PDF is unavailable');
    return;
  }
  try {
    final opened = await launchUrl(
      Uri.parse(pdfUrl!),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      _showMessage(context, 'Could not open the original invoice PDF');
    }
  } catch (_) {
    if (context.mounted) {
      _showMessage(context, 'Could not open the original invoice PDF');
    }
  }
}

Future<void> shareOriginalInvoicePdf(
  BuildContext context, {
  required String? pdfUrl,
  required String invoiceRef,
}) async {
  if (!_hasPdf(pdfUrl)) {
    _showMessage(context, 'Original invoice PDF is unavailable');
    return;
  }
  try {
    final file = await _originalPdf(pdfUrl!, invoiceRef);
    if (!context.mounted) return;
    await Share.shareXFiles(
      [file],
      subject: 'Invoice $invoiceRef',
      sharePositionOrigin: _shareOrigin(context),
    );
  } catch (_) {
    if (context.mounted) {
      _showMessage(context, 'Could not prepare the original invoice PDF');
    }
  }
}

Future<void> sendInvoiceMessage(
  BuildContext context, {
  required String? pdfUrl,
  required String invoiceRef,
  required String customerPhone,
}) async {
  if (!_hasPdf(pdfUrl)) {
    _showMessage(context, 'Original invoice PDF is unavailable');
    return;
  }
  final message = 'Your invoice $invoiceRef: $pdfUrl';
  final phone = customerPhone.replaceAll(RegExp(r'[^\d+]'), '');
  if (phone.isNotEmpty) {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
  }
  try {
    if (!context.mounted) return;
    await Share.share(
      message,
      subject: 'Invoice $invoiceRef',
      sharePositionOrigin: _shareOrigin(context),
    );
  } catch (_) {
    if (context.mounted) _showMessage(context, 'Could not open a message app');
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> showInvoiceEmailSheet(
  BuildContext context, {
  required String invoiceRef,
  required String? pdfUrl,
  required String amountLabel,
  required String customerId,
  required String customerEmail,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _InvoiceEmailSheet(
      invoiceRef: invoiceRef,
      pdfUrl: pdfUrl,
      amountLabel: amountLabel,
      customerId: customerId,
      customerEmail: customerEmail,
    ),
  );
}

class _InvoiceEmailSheet extends StatefulWidget {
  final String invoiceRef;
  final String? pdfUrl;
  final String amountLabel;
  final String customerId;
  final String customerEmail;

  const _InvoiceEmailSheet({
    required this.invoiceRef,
    required this.pdfUrl,
    required this.amountLabel,
    required this.customerId,
    required this.customerEmail,
  });

  @override
  State<_InvoiceEmailSheet> createState() => _InvoiceEmailSheetState();
}

class _InvoiceEmailSheetState extends State<_InvoiceEmailSheet> {
  late final TextEditingController _emailController;
  bool _saveEmail = false;
  bool _sending = false;
  bool _sent = false;
  late String _savedEmail;
  String? _error;
  String? _handoffMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.customerEmail);
    _savedEmail = widget.customerEmail.trim();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _validEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  Future<void> _recordAttempt(String recipient, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('invoice_email_delivery_log') ?? [];
      history.add(
        jsonEncode({
          'invoice': widget.invoiceRef,
          'recipient': recipient,
          'status': status,
          'at': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      await prefs.setStringList('invoice_email_delivery_log', history);
    } catch (_) {
      // A local audit write must not turn a successful email into a failure.
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final recipient = _emailController.text.trim();
    if (!_validEmail(recipient)) {
      setState(() => _error = 'Enter a valid recipient email');
      return;
    }
    if (!_hasPdf(widget.pdfUrl)) {
      setState(() => _error = 'Original invoice PDF is unavailable');
      return;
    }

    setState(() {
      _sending = true;
      _sent = false;
      _error = null;
      _handoffMessage = null;
    });
    try {
      final api = ApiClient(baseUrl);
      final sameSavedEmail =
          recipient.toLowerCase() == _savedEmail.toLowerCase();

      if (widget.customerId.isNotEmpty && _saveEmail && !sameSavedEmail) {
        try {
          await api.put(
            CustomerEndpoints.update(widget.customerId),
            data: {'email': recipient},
          );
          _savedEmail = recipient;
        } catch (_) {
          // Non-blocking: continue sending email even if updating customer profile fails
        }
      }

      final response = await api.post(
        InvoiceEndpoints.sendEmail,
        data: {
          'email': recipient,
          'invoiceRef': widget.invoiceRef,
          'pdfUrl': widget.pdfUrl,
          'amountLabel': widget.amountLabel,
          if (widget.customerId.isNotEmpty) 'customerId': widget.customerId,
        },
      );

      final success = response.data['success'] == true;
      if (!success) {
        throw StateError('The email service failed to send the invoice');
      }

      await _recordAttempt(recipient, 'sent');
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      await _recordAttempt(recipient, 'failed');
      if (mounted) {
        setState(() => _error = 'Could not send the invoice. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSave = widget.customerId.isNotEmpty;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Email invoice copy',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _detail('Invoice', widget.invoiceRef)),
                  Expanded(child: _detail('Amount', widget.amountLabel)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Recipient email',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) => setState(() {
                  _error = null;
                  _sent = false;
                }),
                decoration: InputDecoration(
                  hintText: 'customer@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (widget.customerEmail.trim().isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'No email is saved. Enter and confirm the recipient.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => shareOriginalInvoicePdf(
                  context,
                  pdfUrl: widget.pdfUrl,
                  invoiceRef: widget.invoiceRef,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.fieldBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pdfName(widget.invoiceRef),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.open_in_new_rounded, size: 16),
                    ],
                  ),
                ),
              ),
              if (canSave) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _saveEmail,
                  onChanged: (value) =>
                      setState(() => _saveEmail = value ?? false),
                  title: const Text('Save email to this customer'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Email includes the invoice details and direct PDF download link. Tap the PDF above to share it via another app.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: TransactionColors.coral,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_handoffMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _handoffMessage!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A9F55),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF0A9F55),
                    disabledForegroundColor: Colors.white70,
                  ),
                  child: Text(
                    _sending
                        ? 'Sending...'
                        : _sent
                        ? 'Send another copy'
                        : 'Send Email',
                  ),
                ),
              ),
              if (_sent) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TransactionColors.greenBright.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TransactionColors.greenBright),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓ Email sent to ${_emailController.text.trim()}',
                        style: TextStyle(color: TransactionColors.greenText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The email service confirmed sending. Later delivery updates are unavailable.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
