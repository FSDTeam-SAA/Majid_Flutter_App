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

/// Step 3: "Review & Agree" — the customer reads the declaration and agrees
/// to the Terms & Conditions and the Privacy Notice.
///
/// Which version of the terms they saw is recorded with the consent, so an
/// approval can always be tied back to the wording that was on screen.
class ReviewAndAgreePage extends StatefulWidget {
  final String currencySymbol;

  const ReviewAndAgreePage({super.key, required this.currencySymbol});

  @override
  State<ReviewAndAgreePage> createState() => _ReviewAndAgreePageState();
}

class _ReviewAndAgreePageState extends State<ReviewAndAgreePage> {
  final ConsentController _consent = ConsentController.instance;
  bool _agreed = false;
  bool _isSaving = false;

  Future<void> _approve() async {
    if (!_agreed || _isSaving) return;
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
                  const SizedBox(height: 20),
                  Text(
                    'Your declaration',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By approving, I confirm that I am aged 18 or over, I '
                    'lawfully own this item, I have the right to sell or trade '
                    'it, and I am acting voluntarily. I consent to sharing my '
                    'ID and transaction details for verification, fraud '
                    'prevention and record-keeping.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (value) =>
                            setState(() => _agreed = value ?? false),
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _agreed = !_agreed),
                            child: Text(
                              'I have read and agree to the Terms & Conditions '
                              'and Privacy Notice.',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalDocumentPage(
                              document: LegalDocuments.terms,
                            ),
                          ),
                        ),
                        child: Text(
                          'Terms overview',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LegalDocumentPage(
                              document: LegalDocuments.privacyPolicy,
                            ),
                          ),
                        ),
                        child: Text(
                          'Privacy Notice',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AppButton(
                    label: 'Agree & Approve',
                    isLoading: _isSaving,
                    onPressed: _agreed ? _approve : null,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            consent.itemName.isEmpty ? 'Trade-in item' : consent.itemName,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Agreed value: $currencySymbol${consent.agreedValue.toStringAsFixed(2)}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Payment: ${consent.paymentMethod.isEmpty ? 'Not set' : consent.paymentMethod}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
