import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/trade_in_consent.dart';
import '../controller/consent_controller.dart';
import 'review_and_agree_page.dart';
import 'verify_customer_page.dart';

/// Step 1 of the trade-in consent flow: ask the customer for consent.
///
/// Send consent request (email with secure link + 6-digit code, or copy message
/// to send from shopkeeper's own phone/WhatsApp).
class RequestConsentPage extends StatefulWidget {
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String itemName;
  final double agreedValue;
  final String paymentMethod;
  final String currencySymbol;

  const RequestConsentPage({
    super.key,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.itemName,
    required this.agreedValue,
    required this.paymentMethod,
    required this.currencySymbol,
  });

  @override
  State<RequestConsentPage> createState() => _RequestConsentPageState();
}

class _RequestConsentPageState extends State<RequestConsentPage> {
  late final ConsentController _consent;
  ConsentChannel _channel = ConsentChannel.email;
  bool _agreedToNotice = false;
  bool _isSending = false;
  bool _isCopying = false;

  @override
  void initState() {
    super.initState();
    _consent = ConsentController.instance;
    if (widget.customerEmail.trim().isNotEmpty) {
      _channel = ConsentChannel.email;
    } else if (widget.customerPhone.trim().isNotEmpty) {
      _channel = ConsentChannel.sms;
    }
  }

  bool get _canSend {
    if (!_agreedToNotice || _isSending) return false;
    return _channel == ConsentChannel.sms
        ? widget.customerPhone.trim().isNotEmpty
        : widget.customerEmail.trim().isNotEmpty;
  }

  Future<void> _sendConsent() async {
    if (!_canSend) return;
    setState(() => _isSending = true);

    _consent.start(
      customerName: widget.customerName,
      customerEmail: widget.customerEmail,
      customerPhone: widget.customerPhone,
      itemName: widget.itemName,
      agreedValue: widget.agreedValue,
      paymentMethod: widget.paymentMethod,
      channel: _channel,
      currencySymbol: widget.currencySymbol,
    );

    final isEmail = _channel == ConsentChannel.email;
    final dispatch = await _consent.sendLinkAndCode(sendEmailNow: isEmail);
    if (!mounted) return;
    setState(() => _isSending = false);

    if (!dispatch.sent) {
      showErrorSnackbar('Could not send the consent link');
      return;
    }

    final channelLabel = isEmail ? 'email' : 'SMS';
    showSuccessSnackbar('Consent $channelLabel dispatched to ${dispatch.maskedDestination}');

    _proceedToVerification();
  }

  Future<void> _copyMessage() async {
    if (!_agreedToNotice || _isCopying) return;
    setState(() => _isCopying = true);

    _consent.start(
      customerName: widget.customerName,
      customerEmail: widget.customerEmail,
      customerPhone: widget.customerPhone,
      itemName: widget.itemName,
      agreedValue: widget.agreedValue,
      paymentMethod: widget.paymentMethod,
      channel: _channel,
      currencySymbol: widget.currencySymbol,
    );

    final dispatch = await _consent.sendLinkAndCode(sendEmailNow: false);
    if (!mounted) return;
    setState(() => _isCopying = false);

    if (!dispatch.sent) {
      showErrorSnackbar('Could not generate consent link');
      return;
    }

    final secureLink = dispatch.secureLink ?? 'https://imoscan.com';
    final code = dispatch.debugCode ?? '';
    final copyText = dispatch.copyMessage ??
        'Hi ${widget.customerName.isNotEmpty ? widget.customerName : "Customer"}, please review your sale or trade-in with us.\n\nOpen: $secureLink\nYour code: $code\n\nEnter the code, read the terms and confirm if you agree.';

    await Clipboard.setData(ClipboardData(text: copyText));
    if (!mounted) return;
    showSuccessSnackbar('Message with secure link and code copied to clipboard!');

    _proceedToVerification();
  }

  Future<void> _proceedToVerification() async {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VerifyCustomerPage()),
    );
    if (verified != true || !mounted) return;

    final approved = await Navigator.push<TradeInConsent>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReviewAndAgreePage(currencySymbol: widget.currencySymbol),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, approved);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Customer Consent'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Send Consent Request',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Create a secure link and code for your customer.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                _SummaryCard(
                  itemName: widget.itemName,
                  value:
                      '${widget.currencySymbol}${widget.agreedValue.toStringAsFixed(2)}',
                  paymentMethod: widget.paymentMethod,
                ),
                const SizedBox(height: 16),

                _AgreeRow(
                  value: _agreedToNotice,
                  onChanged: (value) =>
                      setState(() => _agreedToNotice = value ?? false),
                ),
                const SizedBox(height: 20),

                Text(
                  'SEND SECURE LINK AND 6-DIGIT CODE BY',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ChannelChip(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        selected: _channel == ConsentChannel.email,
                        enabled: widget.customerEmail.trim().isNotEmpty,
                        onTap: () =>
                            setState(() => _channel = ConsentChannel.email),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChannelChip(
                        icon: Icons.sms_outlined,
                        label: 'SMS / Text',
                        selected: _channel == ConsentChannel.sms,
                        enabled: widget.customerPhone.trim().isNotEmpty,
                        onTap: () =>
                            setState(() => _channel = ConsentChannel.sms),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Button 1: Send email / Send SMS (styled same as developer design)
                AppButton(
                  label: _channel == ConsentChannel.sms ? 'Send SMS' : 'Send email',
                  isLoading: _isSending,
                  onPressed: _canSend ? _sendConsent : null,
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _channel == ConsentChannel.sms
                        ? 'SMS includes secure link + 6-digit code.'
                        : 'Email includes secure link + 6-digit code.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Button 2: Copy message (matches developer handoff requirement #2)
                OutlinedButton.icon(
                  onPressed: _agreedToNotice && !_isCopying ? _copyMessage : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: _agreedToNotice
                          ? AppColors.primary
                          : AppColors.fieldBorder,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isCopying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'Copy message',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Copy link + code. Send to the customer from your own number/chat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Example message preview box (as in Developer handoff 01)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Customer message • example',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hi ${widget.customerName.isNotEmpty ? widget.customerName : "[Customer]"}, please review your sale or trade-in.\n\nOpen: [Secure link]\nYour code: [6-digit code]\n\nEnter the code, read the terms and confirm if you agree.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary),
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
}

class _SummaryCard extends StatelessWidget {
  final String itemName;
  final String value;
  final String paymentMethod;

  const _SummaryCard({
    required this.itemName,
    required this.value,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          _row(Icons.phone_iphone_rounded, 'Item', itemName),
          const SizedBox(height: 10),
          _row(Icons.sell_outlined, 'Agreed value', value),
          const SizedBox(height: 10),
          _row(Icons.account_balance_outlined, 'Payment', paymentMethod),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value.isEmpty ? '—' : value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AgreeRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _AgreeRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              'The customer agrees to the Privacy Notice',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChannelChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _ChannelChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected && enabled;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? AppColors.primary : AppColors.fieldBorder,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: active
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
