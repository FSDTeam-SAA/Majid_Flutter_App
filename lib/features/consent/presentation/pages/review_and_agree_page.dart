import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../legal/domain/legal_documents.dart';
import '../../../legal/presentation/pages/legal_document_page.dart';
import '../../domain/trade_in_consent.dart';
import '../controller/consent_controller.dart';
import 'consent_approved_page.dart';

/// Step 3: "Review & Agree" — the customer reviews the details, reads terms,
/// confirms age 18+, ownership, voluntary sale, and Terms & Conditions.
class ReviewAndAgreePage extends StatefulWidget {
  final String currencySymbol;

  const ReviewAndAgreePage({super.key, required this.currencySymbol});

  @override
  State<ReviewAndAgreePage> createState() => _ReviewAndAgreePageState();
}

class _ReviewAndAgreePageState extends State<ReviewAndAgreePage> {
  final ConsentController _consent = ConsentController.instance;

  // 3 explicit checkboxes as specified in Developer Handoff 03
  bool _confirmAge18 = false;
  bool _confirmOwnership = false;
  bool _confirmTermsAgreed = false;

  bool _isSaving = false;

  bool get _allChecked => _confirmAge18 && _confirmOwnership && _confirmTermsAgreed;

  Future<void> _approve() async {
    if (!_allChecked || _isSaving) return;
    setState(() => _isSaving = true);

    final approved = await _consent.approve();
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (approved == null) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConsentApprovedPage(
          consent: approved,
          currencySymbol: widget.currencySymbol,
        ),
      ),
    );
    if (!mounted) return;
    Navigator.pop(context, approved);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Obx(() {
        final consent = _consent.active.value;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Review & Agree',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (consent != null)
                    _AgreementCard(
                      consent: consent,
                      currencySymbol: widget.currencySymbol,
                    ),
                  const SizedBox(height: 18),

                  // Quick Terms / Full Terms Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalDocumentPage(
                                document: LegalDocuments.terms,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(color: AppColors.fieldBorder),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            Icons.article_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            'Quick Terms',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalDocumentPage(
                                document: LegalDocuments.terms,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(color: AppColors.fieldBorder),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            Icons.menu_book_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            'Full Terms',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Checkbox 1: Age 18 or over
                  _CheckboxRow(
                    value: _confirmAge18,
                    onChanged: (val) => setState(() => _confirmAge18 = val ?? false),
                    label: 'I confirm I am aged 18 or over.',
                  ),
                  const SizedBox(height: 12),

                  // Checkbox 2: Ownership & voluntary
                  _CheckboxRow(
                    value: _confirmOwnership,
                    onChanged: (val) => setState(() => _confirmOwnership = val ?? false),
                    label: 'I own this device, have the right to sell it and am selling or trading it in voluntarily.',
                  ),
                  const SizedBox(height: 12),

                  // Checkbox 3: Agreement to details & Terms
                  _CheckboxRow(
                    value: _confirmTermsAgreed,
                    onChanged: (val) => setState(() => _confirmTermsAgreed = val ?? false),
                    label: 'I agree to the transaction details above and the Terms & Conditions.',
                  ),
                  const SizedBox(height: 18),

                  // Privacy Notice card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Privacy Notice',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'We collect your ID image, contact details and device details for this transaction. Your original ID image is deleted automatically within 28 days.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LegalDocumentPage(
                                document: LegalDocuments.privacyPolicy,
                              ),
                            ),
                          ),
                          child: Text(
                            'Read full Privacy Notice',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Agree & confirm',
                    isLoading: _isSaving,
                    onPressed: _allChecked ? _approve : null,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await _consent.decline();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        'Decline',
                        style: TextStyle(color: AppColors.dangerColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CheckboxRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;

  const _CheckboxRow({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AgreementCard extends StatelessWidget {
  final TradeInConsent consent;
  final String currencySymbol;

  const _AgreementCard({required this.consent, required this.currencySymbol});

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
          _row(Icons.phone_iphone_rounded, 'Item', consent.itemName),
          const SizedBox(height: 10),
          _row(
            Icons.sell_outlined,
            'Agreed value',
            '$currencySymbol${consent.agreedValue.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 10),
          _row(
            Icons.account_balance_outlined,
            'Payment',
            consent.paymentMethod,
          ),
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
