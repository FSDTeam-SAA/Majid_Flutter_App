import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/legal_documents.dart';

/// Renders any of the three legal documents in-app.
///
/// Each legal row on the profile opens its corresponding page here rather than
/// a web view, so the wording is available offline and cannot drift from the
/// version the client signed off.
class LegalDocumentPage extends StatelessWidget {
  final LegalDocument document;

  const LegalDocumentPage({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: document.title),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              children: [
                Text(
                  document.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: ${document.lastUpdated}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                ..._buildBlocks(context),
                const SizedBox(height: 28),
                _ContactCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBlocks(BuildContext context) {
    final blocks = <Widget>[];

    for (final rawLine in document.body.trim().split('\n')) {
      final line = rawLine.trim();

      if (line.isEmpty) {
        blocks.add(const SizedBox(height: 12));
        continue;
      }

      if (line.startsWith('## ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              line.substring(3),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        );
        continue;
      }

      if (line.startsWith('- ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 10),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: _body(line.substring(2))),
              ],
            ),
          ),
        );
        continue;
      }

      blocks.add(Padding(padding: const EdgeInsets.only(bottom: 4), child: _body(line)));
    }

    return blocks;
  }

  Widget _body(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13.5,
        height: 1.55,
      ),
    );
  }
}

/// Company identity block repeated at the foot of every document, with the
/// contact address and the ICO complaints route as live links.
class _ContactCard extends StatelessWidget {
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
            LegalDocuments.companyName,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Company number: ${LegalDocuments.companyNumber}\n'
            'Registered office: ${LegalDocuments.registeredOffice}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _LinkRow(
            icon: Icons.mail_outline_rounded,
            label: LegalDocuments.contactEmail,
            uri: Uri.parse('mailto:${LegalDocuments.contactEmail}'),
          ),
          const SizedBox(height: 8),
          _LinkRow(
            icon: Icons.balance_rounded,
            label: 'Complain to the ICO',
            uri: Uri.parse(LegalDocuments.icoComplaintsUrl),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Uri uri;

  const _LinkRow({required this.icon, required this.label, required this.uri});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
