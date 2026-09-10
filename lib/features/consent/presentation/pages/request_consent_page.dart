import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
/// The client's requirement is that permission is taken **before** anything is
/// captured: the customer gets a secure link and a 6-digit code, agrees to the
/// terms, and only then may the shopkeeper photograph their ID or scan the
/// handset. This screen starts that sequence. It pops the approved
/// [TradeInConsent], or null if it was not completed.
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
  ConsentChannel _channel = ConsentChannel.sms;
  bool _agreedToNotice = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _consent = ConsentController.instance;
    // SMS only makes sense when we actually hold a number.
    if (widget.customerPhone.trim().isEmpty) {
      _channel = ConsentChannel.email;
    }
  }

  bool get _canSend {
    if (!_agreedToNotice || _isSending) return false;
    return _channel == ConsentChannel.sms
        ? widget.customerPhone.trim().isNotEmpty
        : widget.customerEmail.trim().isNotEmpty;
  }

  Future<void> _send() async {
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
    );

    final dispatch = await _consent.sendLinkAndCode();
    if (!mounted) return;
    setState(() => _isSending = false);

    if (!dispatch.sent) {
      showErrorSnackbar('Could not send the consent link');
      return;
    }

    if (dispatch.debugCode != null && !kReleaseMode) {
      // No SMS/email gateway in the app yet; debug builds surface the code so
      // the flow can be walked end to end on device.
      showSuccessSnackbar('Test code: ${dispatch.debugCode}');
    }

    // The same link carries both steps: verify the code, then read and agree.
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
                    'Customer Consent',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We will collect the customer\'s ID image, contact details '
                  'and device IMEI for this transaction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'The original ID image will be deleted automatically after '
                  '28 days.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _SummaryCard(
                  itemName: widget.itemName,
                  value:
                      '${widget.currencySymbol}${widget.agreedValue.toStringAsFixed(2)}',
                  paymentMethod: widget.paymentMethod,
                ),
                const SizedBox(height: 20),
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
                        icon: Icons.sms_outlined,
                        label: 'SMS',
                        selected: _channel == ConsentChannel.sms,
                        enabled: widget.customerPhone.trim().isNotEmpty,
                        onTap: () =>
                            setState(() => _channel = ConsentChannel.sms),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                  ],
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Send Link & Code',
                  isLoading: _isSending,
                  onPressed: _canSend ? _send : null,
                ),
                const SizedBox(height: 10),
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
