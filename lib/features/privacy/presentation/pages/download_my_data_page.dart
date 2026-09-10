import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../../customer/data/repositories/customer_repository_impl.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../legal/domain/legal_documents.dart';
import '../../../legal/presentation/pages/legal_document_page.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../scan/presentation/widgets/searchable_picker_sheet.dart';
import '../../../security/domain/security_models.dart';
import '../../../security/presentation/controller/security_controller.dart';
import '../../../security/presentation/pages/verify_code_page.dart';
import '../../data/data_export_service.dart';
import 'delete_account_page.dart';

/// Legal & Privacy → Download & Request My Data.
///
/// Personal, business and customer requests are kept apart on purpose, as the
/// client's screen sets out: the account holder's own record, the shop's
/// trading data, and a request made on a customer's behalf are three different
/// things with three different lawful bases.
class DownloadMyDataPage extends StatefulWidget {
  const DownloadMyDataPage({super.key});

  @override
  State<DownloadMyDataPage> createState() => _DownloadMyDataPageState();
}

class _DownloadMyDataPageState extends State<DownloadMyDataPage> {
  final DataExportService _exports = DataExportService();
  String? _busyAction;

  Future<void> _run(String action, Future<DataExportResult> Function() task) async {
    if (_busyAction != null) return;
    setState(() => _busyAction = action);
    try {
      final result = await task();
      if (!mounted) return;
      await _offerShare(result);
    } catch (e) {
      if (mounted) showErrorSnackbar('Could not build the export: $e');
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }

  Future<void> _offerShare(DataExportResult result) async {
    showSuccessSnackbar('Export saved to ${result.locationLabel}');
    await Share.shareXFiles(
      [XFile(result.file.path)],
      text: 'imoscan data export',
    );
  }

  /// Business data is owner/admin material, so it is gated behind the
  /// account's two-factor check before the file is built.
  Future<void> _exportBusinessData() async {
    final security = SecurityController.instance;
    await security.load();
    final settings = security.settings.value;
    final profile = Get.find<ProfileController>();

    if (settings.enabled) {
      final passed = await _challenge(security, settings, profile);
      if (!passed) return;
    }

    await _run('business', _exports.exportBusinessData);
  }

  Future<bool> _challenge(
    SecurityController security,
    TwoFactorSettings settings,
    ProfileController profile,
  ) async {
    var message = 'Enter the code from your authenticator app.';

    if (settings.method != TwoFactorMethod.authenticator) {
      final destination = settings.method == TwoFactorMethod.email
          ? profile.email
          : profile.phone;
      await security.sendChallenge(
        method: settings.method,
        destination: destination,
      );
      message = 'Enter the 6-digit code sent to $destination.';
    }

    if (!mounted) return false;
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyCodePage(
          title: 'Verify it is you',
          message: message,
          onVerify: security.verifyChallenge,
          actionLabel: 'Verify & Export',
        ),
      ),
    );
    return ok == true;
  }

  /// A customer data request: the shop is normally the controller, so the
  /// export is built for one named customer and contains only their record.
  Future<void> _requestCustomerData() async {
    final profile = Get.find<ProfileController>();
    if (profile.userId.isEmpty) await profile.fetchProfile();

    List<Customer> customers = const [];
    try {
      customers = await CustomerRepositoryImpl(
        ApiClient(baseUrl),
      ).getCustomers(profile.userId);
    } catch (_) {
      // Falls through to the empty-list message below.
    }
    if (!mounted) return;

    if (customers.isEmpty) {
      showErrorSnackbar('No customer records available to export');
      return;
    }

    final picked = await showSearchablePicker<Customer>(
      context: context,
      title: 'Which customer?',
      searchHint: 'Search name, phone or email',
      emptyMessage: 'No customers match',
      options: [
        for (final customer in customers)
          PickerOption(
            value: customer,
            title: customer.fullName.isEmpty ? 'Customer' : customer.fullName,
            subtitle: [
              customer.phone,
              customer.email,
            ].where((value) => value.trim().isNotEmpty).join(' • '),
          ),
      ],
    );
    if (picked == null) return;

    await _run(
      'customer',
      () => _exports.exportCustomerData(picked.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Legal & Privacy'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              children: [
                Text(
                  'Download & Request My Data',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep personal, business and customer data requests separate.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                _ExportCard(
                  step: '1',
                  icon: Icons.person_outline_rounded,
                  title: 'Download My Personal Data',
                  audience: 'Owners & staff',
                  description:
                      'Profile, role, permissions, login history, consent and '
                      'support records.',
                  notes: const [
                    'Delivered as a JSON file you can open or forward.',
                  ],
                  actionLabel: 'Download',
                  isBusy: _busyAction == 'personal',
                  isDisabled: _busyAction != null,
                  onTap: () => _run('personal', _exports.exportPersonalData),
                ),
                const SizedBox(height: 12),
                _ExportCard(
                  step: '2',
                  icon: Icons.storefront_outlined,
                  title: 'Export Business Data',
                  audience: 'Owner/Admin only',
                  description:
                      'Inventory, sales, invoices, repairs, trade-ins, '
                      'customers and reports.',
                  notes: const [
                    'Requires your two-factor code.',
                    'Does not include full card details or ID images.',
                  ],
                  actionLabel: 'Export',
                  isBusy: _busyAction == 'business',
                  isDisabled: _busyAction != null,
                  onTap: _exportBusinessData,
                ),
                const SizedBox(height: 12),
                _ExportCard(
                  step: '3',
                  icon: Icons.groups_outlined,
                  title: 'Customer Data Request',
                  audience: 'The shop is normally the data controller',
                  description:
                      'imoscan helps the shop review and securely export the '
                      'customer\'s records.',
                  notes: const ['Includes only that customer\'s data.'],
                  actionLabel: 'Prepare',
                  isBusy: _busyAction == 'customer',
                  isDisabled: _busyAction != null,
                  onTap: _requestCustomerData,
                ),
                const SizedBox(height: 24),
                _ProcessCard(),
                const SizedBox(height: 20),
                _NoteCard(),
                const SizedBox(height: 24),
                _LinkRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalDocumentPage(
                        document: LegalDocuments.privacyPolicy,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _LinkRow(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete Account',
                  isDanger: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DeleteAccountPage(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Your data. Your choice.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

class _ExportCard extends StatelessWidget {
  final String step;
  final IconData icon;
  final String title;
  final String audience;
  final String description;
  final List<String> notes;
  final String actionLabel;
  final bool isBusy;
  final bool isDisabled;
  final VoidCallback onTap;

  const _ExportCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.audience,
    required this.description,
    required this.notes,
    required this.actionLabel,
    required this.isBusy,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  step,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 19, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Text(
              audience,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          for (final note in notes) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5, right: 8),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                Expanded(
                  child: Text(
                    note,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isDisabled ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.buttonText,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isBusy
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          AppColors.buttonText,
                        ),
                      ),
                    )
                  : Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The steps a request goes through, so the shopkeeper knows what to expect
/// and what to tell a customer who has asked.
class _ProcessCard extends StatelessWidget {
  static const _steps = [
    (Icons.description_outlined, 'Request submitted'),
    (Icons.smartphone_rounded, 'Verify identity by login or OTP'),
    (Icons.storefront_outlined, 'Route to imoscan or the relevant shop'),
    (Icons.fact_check_outlined, 'Review and redact third-party data'),
    (Icons.download_rounded, 'Create secure, time-limited download'),
    (Icons.check_circle_outline_rounded, 'Record completion'),
    (Icons.schedule_rounded, 'Normally respond within one month'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How a request is handled',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _steps.length; i++) ...[
            Row(
              children: [
                Icon(_steps[i].$1, size: 17, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _steps[i].$2,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            if (i != _steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  height: 14,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.fieldBorder,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Exports are kept on your device only until you share them. '
              'Every request and download is recorded, and another customer\'s '
              'data is never included.',
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

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.dangerColor : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDanger
                  ? AppColors.dangerColor.withValues(alpha: 0.35)
                  : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
