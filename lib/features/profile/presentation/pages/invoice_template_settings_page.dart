import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/utils/invoice_template_settings.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../invoice/presentation/utils/invoice_template_builder.dart';
import '../../../invoice/presentation/utils/verified_invoice_pdf.dart';
import '../controller/profile_controller.dart';

class InvoiceTemplateSettingsPage extends StatefulWidget {
  const InvoiceTemplateSettingsPage({super.key});

  @override
  State<InvoiceTemplateSettingsPage> createState() =>
      _InvoiceTemplateSettingsPageState();
}

class _InvoiceTemplateSettingsPageState
    extends State<InvoiceTemplateSettingsPage> {
  late final ProfileController _profileCtrl;
  String _selectedTemplateId = 'default';
  String _filterCategory = 'All'; // 'All', 'Modern', 'Traditional'
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _profileCtrl = Get.find<ProfileController>();
    _initSettings();
  }

  Future<void> _initSettings() async {
    final cached = await InvoiceTemplateSettings.load();
    final profileTemplate = _profileCtrl.invoiceTemplate;
    final effective =
        profileTemplate.isNotEmpty && profileTemplate != 'default'
            ? profileTemplate
            : cached;

    if (!mounted) return;
    setState(() {
      _selectedTemplateId = effective;
    });
  }

  Future<void> _applyTemplate(InvoiceTemplateItem template) async {
    setState(() => _isSaving = true);
    try {
      // Save locally for instant offline availability
      await InvoiceTemplateSettings.save(template.id);

      // Save to backend profile
      final success = await _profileCtrl.setInvoiceTemplate(template.id);

      if (!mounted) return;
      setState(() {
        _selectedTemplateId = template.id;
        _isSaving = false;
      });

      if (success) {
        showSuccessSnackbar(
          'Invoice design set to "${template.name}". Automatically applied to Sales and Purchase invoices.',
        );
      } else {
        showSuccessSnackbar(
          'Saved "${template.name}" locally. It will apply to your invoices.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showErrorSnackbar('Failed to update invoice template: $e');
    }
  }

  Future<void> _previewTemplate(InvoiceTemplateItem template) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final sampleItems = [
        const VerifiedInvoiceItem(
          name: 'iPhone 17 Pro 256GB',
          quantity: 1,
          lineTotal: 850.0,
          imei: '123456789012345',
          isVerified: true,
        ),
        const VerifiedInvoiceItem(
          name: 'Protective Silicone Case',
          quantity: 1,
          lineTotal: 20.0,
        ),
        const VerifiedInvoiceItem(
          name: 'Screen Protector',
          quantity: 1,
          lineTotal: 15.0,
        ),
      ];

      final file = await InvoiceTemplateBuilder.buildSalesInvoice(
        fileName: 'preview_${template.id}.pdf',
        invoiceNumber: 'MKD-0026',
        createdAt: DateTime.now(),
        shopName: _profileCtrl.shopName.isNotEmpty
            ? _profileCtrl.shopName
            : 'Mobile Kit Distribution',
        shopEmail: _profileCtrl.email.isNotEmpty
            ? _profileCtrl.email
            : 'support@mobilekit.co.uk',
        shopPhone: _profileCtrl.phone.isNotEmpty
            ? _profileCtrl.phone
            : '+44 20 7946 0912',
        shopAddress: _profileCtrl.shopAddress.isNotEmpty
            ? _profileCtrl.shopAddress
            : '124 High Street, London, UK',
        customerName: 'Catherine Earnshaw',
        customerEmail: 'catherine.e@example.com',
        customerPhone: '+44 7700 900145',
        customerAddress: '74 Yorkshire Way, Leeds',
        paymentLabel: 'Card',
        isPaid: true,
        currencySymbol: _profileCtrl.currencySymbol,
        currencyCode: _profileCtrl.currencyCode,
        items: sampleItems,
        subtitle: 'INVOICE PREVIEW',
        templateId: template.id,
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      _showPreviewDialog(template, file.path);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      showErrorSnackbar('Could not generate preview: $e');
    }
  }

  void _showPreviewDialog(InvoiceTemplateItem template, String pdfPath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: template.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  template.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: template.category == InvoiceCategory.traditional
                        ? Colors.amber.shade50
                        : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template.categoryName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: template.category == InvoiceCategory.traditional
                          ? Colors.amber.shade900
                          : Colors.indigo.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Highlights:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...template.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(f, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _applyTemplate(template);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply Design'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = InvoiceTemplateSettings.templates.where((t) {
      if (_filterCategory == 'All') return true;
      return t.categoryName == _filterCategory;
    }).toList();

    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(
            title: 'Invoice Templates',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your selected template automatically formats all generated Sales and Purchase receipts. Smart Invoices remain unchanged.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Category filter pills
                  Row(
                    children: ['All', 'Modern', 'Traditional'].map((cat) {
                      final isSelected = _filterCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat == 'All' ? 'All Designs' : cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _filterCategory = cat);
                            }
                          },
                          selectedColor: AppColors.primary.withValues(alpha: 0.15),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade700,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Templates list
                  ...filteredTemplates.map((template) {
                    final isActive = _selectedTemplateId == template.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : Colors.grey.shade200,
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card header
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            template.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: template.category ==
                                                      InvoiceCategory.traditional
                                                  ? Colors.amber.shade50
                                                  : Colors.indigo.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              template.categoryName,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: template.category ==
                                                        InvoiceCategory
                                                            .traditional
                                                    ? Colors.amber.shade900
                                                    : Colors.indigo.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        template.description,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      border: Border.all(
                                          color: Colors.green.shade300),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check,
                                            size: 12,
                                            color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Active',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Mini visual representation
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: template.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 20,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: template.headerColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'MOBILE KIT',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: template.id == 'neo-bold'
                                              ? Colors.black
                                              : template.headerColor ==
                                                      const Color(0xFFFFFDEB)
                                                  ? Colors.black
                                                  : Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'INVOICE',
                                        style: TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.bold,
                                          color: template.id == 'neo-bold'
                                              ? Colors.black
                                              : template.headerColor ==
                                                      const Color(0xFFFFFDEB)
                                                  ? Colors.black
                                                  : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  height: 6,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 6,
                                  width: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: template.accentColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'PAID',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: template.id == 'neo-bold' ||
                                                  template.id ==
                                                      'nordic-modern' ||
                                                  template.id == 'warm-minimal'
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      '£885.00',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Palette dots
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                            child: Row(
                              children: [
                                Text(
                                  'Palette:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _colorDot(template.primaryColor),
                                const SizedBox(width: 4),
                                _colorDot(template.accentColor),
                                const SizedBox(width: 4),
                                _colorDot(template.backgroundColor),
                              ],
                            ),
                          ),

                          // Bottom buttons
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _previewTemplate(template),
                                    icon: const Icon(Icons.visibility_outlined,
                                        size: 15),
                                    label: const Text('Preview'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      textStyle: const TextStyle(fontSize: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isActive || _isSaving
                                        ? null
                                        : () => _applyTemplate(template),
                                    icon: Icon(
                                      isActive
                                          ? Icons.check
                                          : Icons.touch_app_outlined,
                                      size: 15,
                                    ),
                                    label: Text(
                                      isActive ? 'Applied' : 'Apply',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
    );
  }
}
