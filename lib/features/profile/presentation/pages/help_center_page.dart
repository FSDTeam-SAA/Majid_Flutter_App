import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../legal/domain/legal_documents.dart';
import '../../../legal/presentation/pages/legal_document_page.dart';
import '../../domain/help_center_content.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final _search = TextEditingController();
  String _topic = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: LegalDocuments.contactEmail,
      query: 'subject=${Uri.encodeComponent('imoscan support')}',
    );
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Keep the address available when no email app is installed.
    }
    if (mounted) {
      showErrorSnackbar(
        'Could not open your email app. Copy the email address below to contact us.',
      );
    }
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(
      const ClipboardData(text: LegalDocuments.contactEmail),
    );
    if (mounted) showSuccessSnackbar('Support email copied');
  }

  void _openPolicy(LegalDocument document) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => LegalDocumentPage(document: document)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final articles = HelpCenterContent.articles
        .where(
          (article) =>
              (_topic == 'All' || article.topic == _topic) &&
              article.matches(_search.text),
        )
        .toList();

    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Help Center'),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
              children: [
                _hero(),
                const SizedBox(height: 20),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search questions or keywords',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () => setState(_search.clear),
                            icon: Icon(
                              Icons.close_rounded,
                              size: 19,
                              color: AppColors.textSecondary,
                            ),
                          ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.fieldBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final topic in HelpCenterContent.topics)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(topic),
                            selected: _topic == topic,
                            onSelected: (_) => setState(() => _topic = topic),
                            showCheckmark: false,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.cardBackground,
                            labelStyle: TextStyle(
                              color: _topic == topic
                                  ? AppColors.buttonText
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(
                              color: _topic == topic
                                  ? AppColors.primary
                                  : AppColors.fieldBorder,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _heading(
                        _search.text.trim().isEmpty && _topic == 'All'
                            ? 'Popular questions'
                            : 'Search results',
                      ),
                    ),
                    Text(
                      '${articles.length} ${articles.length == 1 ? 'article' : 'articles'}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (articles.isEmpty) _emptyState(),
                for (final article in articles) _article(article),
                const SizedBox(height: 18),
                _contactCard(),
                const SizedBox(height: 26),
                _heading('Useful information'),
                const SizedBox(height: 12),
                _policyRow(
                  'Terms & Conditions',
                  Icons.gavel_outlined,
                  LegalDocuments.terms,
                ),
                _policyRow(
                  'Privacy Policy',
                  Icons.shield_outlined,
                  LegalDocuments.privacyPolicy,
                ),
                _policyRow(
                  'Cookie & Tracking Policy',
                  Icons.cookie_outlined,
                  LegalDocuments.cookiePolicy,
                ),
                const SizedBox(height: 22),
                Text(
                  LegalDocuments.companyName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Company number: ${LegalDocuments.companyNumber}\n${LegalDocuments.registeredOffice}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String text) => Text(
    text,
    style: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _hero() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.primary.withValues(alpha: 0.03),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'IMOSCAN SUPPORT',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'How can we help?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Find a quick answer or get in touch with us.\nWe’re here to help you keep things moving.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    ),
  );

  Widget _article(HelpArticle article) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.fieldBorder),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: PageStorageKey(article.question),
        tilePadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          article.question,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              article.answer,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.fieldBorder),
    ),
    child: Column(
      children: [
        Icon(Icons.search_off_rounded, color: AppColors.primary, size: 32),
        const SizedBox(height: 12),
        Text(
          'No answers found',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Try another keyword or contact us below.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        TextButton(
          onPressed: () => setState(() {
            _search.clear();
            _topic = 'All';
          }),
          child: const Text('Show all questions'),
        ),
      ],
    ),
  );

  Widget _contactCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.forum_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: _heading('Still need a hand?')),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Tell us what happened and which screen you were using. Include a reference number if you have one.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _emailSupport,
            icon: const Icon(Icons.mail_outline_rounded, size: 19),
            label: const Text('Email support'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.buttonText,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                LegalDocuments.contactEmail,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ),
            IconButton(
              onPressed: _copyEmail,
              tooltip: 'Copy support email',
              icon: Icon(
                Icons.copy_outlined,
                color: AppColors.primary,
                size: 17,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _policyRow(String title, IconData icon, LegalDocument document) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: AppColors.fieldBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            onTap: () => _openPolicy(document),
            leading: Icon(icon, color: AppColors.primary, size: 20),
            title: Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 21,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 1,
            ),
          ),
        ),
      );
}
