import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/trade_in_consent.dart';

/// Step 4: "Consent Approved".
///
/// Consent status and payment status are shown as two separate things on
/// purpose — the developer notes are explicit that one must never be read as
/// the other. This screen confirms the consent; payment is still recorded in
/// the invoice flow afterwards.
class ConsentApprovedPage extends StatelessWidget {
  final TradeInConsent consent;
  final String currencySymbol;

  const ConsentApprovedPage({
    super.key,
    required this.consent,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Consent Approved',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Verified by customer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approved • ${_formatDate(consent.approvedAt)}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Consent reference: ${consent.reference}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _RecordCard(consent: consent, currencySymbol: currencySymbol),
            const SizedBox(height: 18),
            _RetentionNote(deleteAfter: consent.idImageDeleteAfter),
            const SizedBox(height: 24),
            AppButton(
              label: 'Continue to scan & payment',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime? time) {
    if (time == null) return '—';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.day} ${_months[time.month - 1]} ${time.year}, $hour:$minute';
  }

  static const _months = [
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
}

class _RecordCard extends StatelessWidget {
  final TradeInConsent consent;
  final String currencySymbol;

  const _RecordCard({required this.consent, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONSENT RECORD',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          _row('Item', consent.itemName),
          _row(
            'Agreed value',
            '$currencySymbol${consent.agreedValue.toStringAsFixed(2)}',
          ),
          _row('Payment method', consent.paymentMethod),
          _row('Delivered by', consent.channel.label),
          _row('Sent to', consent.maskedDestination),
          _row('Terms version', consent.termsVersion),
          if (consent.deviceMetadata.isNotEmpty)
            _row('Device', consent.deviceMetadata),
          const SizedBox(height: 8),
          Divider(height: 1, color: AppColors.fieldBorder),
          const SizedBox(height: 10),
          _check('Consent approved'),
          _check('Customer verification saved'),
          // Payment is deliberately not ticked here: it is recorded separately
          // in the invoice flow.
          _pending('Payment recorded in the invoice'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _check(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _pending(String label) {
    return Row(
      children: [
        Icon(
          Icons.radio_button_unchecked_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
      ],
    );
  }
}

class _RetentionNote extends StatelessWidget {
  final DateTime? deleteAfter;

  const _RetentionNote({this.deleteAfter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              deleteAfter == null
                  ? 'The original ID image is deleted automatically no later '
                        'than 28 days after capture.'
                  : 'The original ID image will be deleted automatically by '
                        '${deleteAfter!.day}/${deleteAfter!.month}/${deleteAfter!.year} '
                        '(28 days after capture). You can delete it sooner.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
