import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app_ground_view.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_outlined_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/app_header.dart';
import '../utils/device_certificate_pdf.dart';
import '../widgets/ai_risk_card.dart';
import '../widgets/device_field_card.dart';

enum _DeviceCategory { apple, samsung, android, other }

class DeviceReportPage extends StatefulWidget {
  final Map<String, dynamic> report;

  const DeviceReportPage({super.key, this.report = const {}});

  @override
  State<DeviceReportPage> createState() => _DeviceReportPageState();
}

class _DeviceReportPageState extends State<DeviceReportPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGeneratingPdf = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allFields = _buildDisplayFields();
    final filtered = _searchQuery.isEmpty
        ? allFields
        : allFields.where((f) {
            final q = _searchQuery;
            return f.label.toLowerCase().contains(q) ||
                f.value.toLowerCase().contains(q);
          }).toList();

    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Device Report'),
          // ── search bar (fixed) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _buildSearchBar(),
          ),
          // ── scrollable content ──
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                ..._buildFieldWidgets(filtered),
                if (filtered.isEmpty && _searchQuery.isNotEmpty) ...[
                  SizedBox(height: 32),
                  Center(
                    child: Text(
                      'No fields match "$_searchQuery"',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
                SizedBox(height: 12),
                AiRiskCard(
                  percentage: _riskScore,
                  description: _riskDescription,
                ),
                SizedBox(height: 16),
                AppButton(
                  label: _isGeneratingPdf
                      ? 'Generating...'
                      : 'Download PDF Certificate',
                  onPressed: _isGeneratingPdf ? null : _generatePdf,
                ),
                SizedBox(height: 10),
                AppOutlinedButton(
                  label: 'Create Smart Invoice',
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AppGroundView(initialIndex: 4),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() {
          _searchQuery = value.trim().toLowerCase();
        }),
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search fields...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
      ),
    );
  }

  // ─── PDF ───

  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final fields = _allFieldsForPdf;
      final deviceName = fields['DEVICE NAME'] ?? 'Unknown Device';
      final imei =
          widget.report['imei']?.toString() ?? fields['IMEI'] ?? '';

      final file = await DeviceCertificatePdf.build(
        deviceName: deviceName,
        imei: imei,
        fields: fields,
        riskScore: _riskScore,
        riskDescription: _riskDescription,
      );
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // ─── data accessors ───

  Map<String, dynamic> get _data {
    final data = widget.report['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return widget.report;
  }

  Map<String, String> get _providerFields {
    final data = _data;
    final result = <String, String>{};

    for (final key in [
      'parsedProviderData',
      'providerData',
      'providerResults',
    ]) {
      final value = data[key];
      if (value is Map && value.isNotEmpty) {
        for (final entry in value.entries) {
          final k = entry.key?.toString() ?? '';
          final v = entry.value;
          if (k.isEmpty || k == 'image' || k == 'result') continue;
          if (v is Map || v is List) continue;
          final str = v?.toString().trim() ?? '';
          if (str.isNotEmpty) result[k] = str;
        }
      }
    }
    return result;
  }

  _DeviceCategory get _category {
    final fields = _providerFields;
    final allValues = fields.values.join(' ').toLowerCase();
    final allKeys = fields.keys.join(' ').toLowerCase();

    if (allKeys.contains('icloud') ||
        allKeys.contains('applecare') ||
        allKeys.contains('find_my') ||
        allValues.contains('apple') ||
        allValues.contains('iphone') ||
        allValues.contains('ipad') ||
        allValues.contains('macbook') ||
        allValues.contains('ios')) {
      return _DeviceCategory.apple;
    }
    if (allValues.contains('samsung') || allValues.contains('galaxy')) {
      return _DeviceCategory.samsung;
    }
    if (allValues.contains('android') ||
        allValues.contains('xiaomi') ||
        allValues.contains('redmi') ||
        allValues.contains('oppo') ||
        allValues.contains('vivo') ||
        allValues.contains('huawei') ||
        allValues.contains('oneplus') ||
        allValues.contains('pixel') ||
        allValues.contains('realme')) {
      return _DeviceCategory.android;
    }
    return _DeviceCategory.other;
  }

  // ─── dynamic field builder ───

  List<_DisplayField> _buildDisplayFields() {
    final provider = _providerFields;
    final imei = widget.report['imei']?.toString() ?? '';
    final usedKeys = <String>{};
    final fields = <_DisplayField>[];

    String resolve(List<String> candidates, {String fallback = 'N/A'}) {
      for (final key in candidates) {
        final val = provider[key];
        if (val != null && val.isNotEmpty) {
          usedKeys.add(key);
          return val;
        }
      }
      return fallback;
    }

    // --- common fields for ALL devices ---
    fields.add(_DisplayField(
      'DEVICE NAME',
      resolve([
        'model',
        'marketing_name',
        'model_description',
        'device_name',
        'product',
      ]),
      fullWidth: true,
    ));

    fields.add(_DisplayField(
      'DEVICE DESCRIPTION',
      resolve(['description', 'model_description', 'marketing_name']),
      fullWidth: true,
    ));

    fields.add(_DisplayField(
      'SERIAL NUMBER',
      resolve(['serial_number', 'serial', 'serialnumber']),
      fullWidth: true,
    ));

    fields.add(_DisplayField(
      'IMEI',
      imei.isNotEmpty ? imei : resolve(['imei', 'imei_number']),
    ));
    if (imei.isNotEmpty) usedKeys.addAll(['imei', 'imei_number']);

    fields.add(_DisplayField(
      'IMEI 2',
      resolve(['imei2', 'imei2_number']),
    ));

    fields.add(_DisplayField(
      'MANUFACTURER',
      resolve(['manufacturer', 'brand']),
    ));

    fields.add(_DisplayField('MEID', resolve(['meid'])));

    // --- category-specific fields ---
    final cat = _category;

    if (cat == _DeviceCategory.apple) {
      fields.addAll([
        _DisplayField('FIND MY IPHONE', resolve(['find_my_iphone', 'fmi', 'fmi_status', 'findmyiphone'])),
        _DisplayField('ICLOUD STATUS', resolve(['icloud_status', 'icloudstatus'])),
        _DisplayField('ICLOUD LOCK', resolve(['icloud_lock', 'icloudlock'])),
        _DisplayField('ACTIVATION STATUS', resolve(['activation_status', 'activationstatus', 'activation_policy', 'activationpolicy'])),
        _DisplayField('SIM LOCK', resolve(['simlock', 'sim_lock', 'simlock_status', 'sim_lock_status'])),
        _DisplayField('LOCKED CARRIER', resolve(['locked_carrier', 'lockedcarrier', 'carrier'])),
        _DisplayField('WARRANTY STATUS', resolve(['warranty_status', 'warrantystatus', 'warranty'])),
        _DisplayField('LIMITED WARRANTY', resolve(['limited_warranty', 'limitedwarranty'])),
        _DisplayField('APPLECARE ELIGIBLE', resolve(['applecare_eligible', 'applecareeligible'])),
        _DisplayField('PURCHASE DATE', resolve(['purchase_date', 'purchasedate', 'estimated_purchase_date'])),
        _DisplayField('COVERAGE START', resolve(['coverage_start', 'coveragestart', 'repairs_and_service_coverage'])),
        _DisplayField('REPLACED DEVICE', resolve(['replaced_device', 'replaceddevice', 'replaced'])),
        _DisplayField('REPLACEMENT DEVICE', resolve(['replacement_device', 'replacementdevice'])),
        _DisplayField('REFURBISHED DEVICE', resolve(['refurbished_device', 'refurbisheddevice'])),
        _DisplayField('DEMO UNIT', resolve(['demo_unit', 'demounit'])),
        _DisplayField('LOANER DEVICE', resolve(['loaner_device', 'loanerdevice'])),
        _DisplayField('REGISTRATION STATUS', resolve(['registration_status', 'registrationstatus'])),
        _DisplayField('VALID PURCHASE DATE', resolve(['valid_purchase_date', 'validpurchasedate'])),
        _DisplayField('BLACKLIST STATUS', resolve(['blacklist_status', 'blackliststatus'])),
        _DisplayField('TECH SUPPORT', resolve(['telephone_technical_support'])),
        _DisplayField('TECH SUPPORT EXPIRES', resolve(['telephone_technical_support_expiration_date', 'telephone_technical_support_expires_in'])),
        _DisplayField('REPAIR COVERAGE EXPIRES', resolve(['repairs_and_service_expiration_date', 'repairs_and_service_expires_in'])),
      ]);
    } else if (cat == _DeviceCategory.samsung) {
      fields.addAll([
        _DisplayField('KNOX GUARD', resolve(['knox_guard', 'knoxguard', 'knox_status'])),
        _DisplayField('SIM LOCK', resolve(['simlock', 'sim_lock', 'simlock_status', 'sim_lock_status', 'network_lock'])),
        _DisplayField('CARRIER', resolve(['carrier', 'locked_carrier', 'lockedcarrier', 'network'])),
        _DisplayField('WARRANTY STATUS', resolve(['warranty_status', 'warrantystatus', 'warranty'])),
        _DisplayField('PURCHASE DATE', resolve(['purchase_date', 'purchasedate'])),
        _DisplayField('BLACKLIST STATUS', resolve(['blacklist_status', 'blackliststatus'])),
        _DisplayField('MDM STATUS', resolve(['mdm_lock', 'mdmlock', 'mdm_status'])),
        _DisplayField('OPERATING SYSTEM', resolve(['operating_system', 'operatingsystem', 'os'])),
        _DisplayField('COUNTRY', resolve(['country', 'purchase_country'])),
        _DisplayField('REPLACED DEVICE', resolve(['replaced_device', 'replaceddevice', 'replaced'])),
      ]);
    } else {
      fields.addAll([
        _DisplayField('SIM LOCK', resolve(['simlock', 'sim_lock', 'simlock_status', 'sim_lock_status', 'network_lock'])),
        _DisplayField('CARRIER', resolve(['carrier', 'locked_carrier', 'lockedcarrier', 'network'])),
        _DisplayField('WARRANTY STATUS', resolve(['warranty_status', 'warrantystatus', 'warranty'])),
        _DisplayField('PURCHASE DATE', resolve(['purchase_date', 'purchasedate'])),
        _DisplayField('BLACKLIST STATUS', resolve(['blacklist_status', 'blackliststatus'])),
        _DisplayField('MDM STATUS', resolve(['mdm_lock', 'mdmlock', 'mdm_status'])),
        _DisplayField('OPERATING SYSTEM', resolve(['operating_system', 'operatingsystem', 'os'])),
        _DisplayField('ACTIVATION STATUS', resolve(['activation_status', 'activationstatus'])),
        _DisplayField('COUNTRY', resolve(['country', 'purchase_country'])),
        _DisplayField('REPLACED DEVICE', resolve(['replaced_device', 'replaceddevice', 'replaced'])),
      ]);
    }

    // --- remaining provider keys not yet mapped ---
    final remaining =
        provider.entries.where((e) => !usedKeys.contains(e.key)).toList();

    for (final entry in remaining) {
      fields.add(_DisplayField(_snakeToLabel(entry.key), entry.value));
    }

    return fields.where((f) => f.value != 'N/A').toList();
  }

  List<Widget> _buildFieldWidgets(List<_DisplayField> fields) {
    final widgets = <Widget>[];
    int i = 0;

    while (i < fields.length) {
      final field = fields[i];

      if (field.fullWidth) {
        widgets.add(DeviceFieldFull(label: field.label, value: field.value));
        widgets.add(SizedBox(height: 10));
        i++;
        continue;
      }

      if (i + 1 < fields.length && !fields[i + 1].fullWidth) {
        final next = fields[i + 1];
        widgets.add(DeviceFieldRow(
          leftLabel: field.label,
          leftValue: field.value,
          rightLabel: next.label,
          rightValue: next.value,
        ));
        widgets.add(SizedBox(height: 10));
        i += 2;
      } else {
        widgets.add(DeviceFieldFull(label: field.label, value: field.value));
        widgets.add(SizedBox(height: 10));
        i++;
      }
    }

    return widgets;
  }

  // ─── risk score ───

  double get _riskScore {
    final data = _data;

    final riskMeter = data['riskMeter'] ?? data['riskAnalysis'];
    if (riskMeter is Map) {
      final score = riskMeter['score'];
      if (score is num) {
        final s = score.toDouble();
        return (s > 1 ? s / 100.0 : s).clamp(0.0, 1.0);
      }
    }

    final provider = _providerFields;
    for (final key in ['riskScore', 'risk_score', 'score', 'healthScore']) {
      final val = provider[key];
      if (val != null) {
        final parsed = double.tryParse(val);
        if (parsed != null) return parsed.clamp(0.0, 1.0);
      }
    }

    final blacklist =
        (provider['blacklist_status'] ?? provider['blackliststatus'] ?? '')
            .toLowerCase();
    final icloud =
        (provider['icloud_lock'] ?? provider['icloudlock'] ?? '')
            .toLowerCase();
    if (blacklist.contains('clean') && icloud.contains('off')) return 0.96;
    if (blacklist.contains('clean')) return 0.85;
    if (blacklist.contains('blacklisted') || blacklist.contains('lost')) {
      return 0.15;
    }
    return 0.70;
  }

  String get _riskDescription {
    final data = _data;

    final riskMeter = data['riskMeter'] ?? data['riskAnalysis'];
    if (riskMeter is Map) {
      final desc = riskMeter['description'] ?? riskMeter['label'];
      if (desc != null && desc.toString().trim().length > 20) {
        return desc.toString();
      }
    }

    final aiInsight = data['aiInsight'];
    if (aiInsight is Map) {
      final msg = aiInsight['message'];
      if (msg != null && msg.toString().trim().length > 10) {
        return msg.toString();
      }
    }

    if (_riskScore >= 0.8) {
      return 'This device shows excellent health, verified original components, '
          'low fraud probability, and high resale potential. Recommended for '
          'resale, trade-in, or direct customer purchase.';
    } else if (_riskScore >= 0.5) {
      return 'This device shows moderate risk indicators. Some checks could '
          'not be fully verified. Proceed with caution and consider additional '
          'verification.';
    } else {
      return 'This device shows high risk indicators. It may be blacklisted, '
          'lost, or stolen. Not recommended for purchase or resale without '
          'further investigation.';
    }
  }

  // ─── helpers ───

  Map<String, String> get _allFieldsForPdf {
    final fields = _buildDisplayFields();
    return {for (final f in fields) f.label: f.value};
  }

  static String _snakeToLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'(^|\s)\w'),
          (m) => m.group(0)!.toUpperCase(),
        )
        .toUpperCase();
  }
}

class _DisplayField {
  final String label;
  final String value;
  final bool fullWidth;

  _DisplayField(this.label, this.value, {this.fullWidth = false});
}
