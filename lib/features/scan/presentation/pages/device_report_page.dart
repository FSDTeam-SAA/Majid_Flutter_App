import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../invoice/presentation/pages/invoice_page.dart';
import '../utils/device_certificate_pdf.dart';
import '../widgets/ai_risk_card.dart';
import '../widgets/device_field_card.dart';

const _kSmartActionsGreen = Color(0xFF22C55E);

enum _DeviceCategory { apple, samsung, android, other }

class DeviceReportPage extends StatefulWidget {
  final Map<String, dynamic> report;

  const DeviceReportPage({super.key, this.report = const {}});

  @override
  State<DeviceReportPage> createState() => _DeviceReportPageState();
}

class _DeviceReportPageState extends State<DeviceReportPage> {
  bool _isGeneratingPdf = false;
  final GlobalKey _downloadCertificateButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final allFields = _buildDisplayFields();

    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Device Report'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              children: [
                ..._buildFieldWidgets(allFields),
                SizedBox(height: 12),
                AiRiskCard(
                  percentage: _riskScore,
                  description: _riskDescription,
                  riskLabel: _riskLabel,
                ),
                SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InvoicePage(
                                initialTabIndex: 0,
                                initialDraft: _invoiceDraftPrefill,
                              ),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _kSmartActionsGreen,
                              width: 1.5,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 18,
                                color: _kSmartActionsGreen,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create Smart Invoice',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _kSmartActionsGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          key: _downloadCertificateButtonKey,
                          onPressed: _isGeneratingPdf ? null : _generatePdf,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kSmartActionsGreen,
                            disabledBackgroundColor: _kSmartActionsGreen
                                .withValues(alpha: 0.5),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _isGeneratingPdf
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.file_download_outlined,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                              SizedBox(height: 4),
                              Text(
                                _isGeneratingPdf
                                    ? 'Generating...'
                                    : 'Download PDF Certificate',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

  // ─── PDF ───

  Future<void> _generatePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final fields = _allFieldsForPdf;
      final deviceName = fields['DEVICE NAME'] ?? 'Unknown Device';
      final imei = widget.report['imei']?.toString() ?? fields['IMEI'] ?? '';

      final file = await DeviceCertificatePdf.build(
        deviceName: deviceName,
        imei: imei,
        fields: fields,
        riskScore: _riskScore,
        riskDescription: _riskDescription,
      );
      if (!mounted) return;
      await Share.shareXFiles([
        XFile(file.path),
      ], sharePositionOrigin: _shareOriginFor(_downloadCertificateButtonKey));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
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
    final report = widget.report;
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

    if (result.isEmpty) {
      final deviceName =
          report['deviceName']?.toString() ?? data['deviceName']?.toString();
      if (deviceName != null &&
          deviceName.isNotEmpty &&
          deviceName != 'Unknown Device') {
        result['device_name'] = deviceName;
      }
      final imei = report['imei']?.toString() ?? data['imei']?.toString();
      if (imei != null && imei.isNotEmpty) result['imei'] = imei;
      final status =
          report['deviceStatus']?.toString() ??
          data['deviceStatus']?.toString();
      if (status != null && status.isNotEmpty && status != 'unknown') {
        result['device_status'] = status;
      }
      final marketValue = report['marketValue'] ?? data['marketValue'];
      if (marketValue is Map) {
        final amount = marketValue['amount']?.toString();
        final currency = marketValue['currency']?.toString() ?? 'USD';
        if (amount != null) result['market_value'] = '$amount $currency';
      }
      final riskMeter = report['riskMeter'] ?? data['riskMeter'];
      if (riskMeter is Map) {
        final label = riskMeter['label']?.toString();
        if (label != null) result['risk_level'] = label;
      }
    }

    return result;
  }

  Map<String, dynamic>? get _marketValueData {
    final data = _data['marketValue'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    final report = widget.report['marketValue'];
    if (report is Map) {
      return Map<String, dynamic>.from(report);
    }

    return null;
  }

  String _normalizeCountryValue(String? value) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty ||
        clean == 'N/A' ||
        clean.toLowerCase() == 'bangladesh') {
      return 'United Kingdom';
    }
    return clean;
  }

  String? get _formattedMarketValue {
    final marketValue = _marketValueData;
    if (marketValue == null) return null;

    final rawAmount = marketValue['amount'];
    if (rawAmount == null) return null;

    final parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount.toString());
    if (parsedAmount == null) return null;

    final currency = marketValue['currency']?.toString().trim().toUpperCase();
    final symbol = switch (currency) {
      'GBP' => '£',
      'EUR' => '€',
      'USD' => '\$',
      _ => null,
    };

    final decimals = parsedAmount % 1 == 0 ? 0 : 2;
    final amountText = parsedAmount.toStringAsFixed(decimals);

    if (symbol != null) {
      return '$symbol$amountText';
    }

    if (currency != null && currency.isNotEmpty) {
      return '$amountText $currency';
    }

    return amountText;
  }

  String get _invoiceItemName {
    final fields = _allFieldsForPdf;
    final deviceName = fields['DEVICE NAME']?.trim() ?? '';
    if (deviceName.isNotEmpty && deviceName != 'N/A') return deviceName;
    return _data['deviceName']?.toString().trim().isNotEmpty == true
        ? _data['deviceName'].toString().trim()
        : 'Device Report Item';
  }

  String get _invoiceStatusLabel {
    final provider = _providerFields;
    final labels = <String>[];

    void addIfPresent(String key, String label) {
      final value = provider[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        labels.add('$label: $value');
      }
    }

    addIfPresent('device_status', 'Status');
    addIfPresent('activation_status', 'Activation');
    addIfPresent('icloud_lock', 'iCloud Lock');
    addIfPresent('sim_lock', 'SIM Lock');
    addIfPresent('blacklist_status', 'Blacklist');

    return labels.join(' • ');
  }

  String get _invoiceDescription {
    final fields = _allFieldsForPdf;
    final parts = <String>[
      if ((fields['MANUFACTURER'] ?? '').trim().isNotEmpty &&
          fields['MANUFACTURER'] != 'N/A')
        fields['MANUFACTURER']!,
      if ((fields['SERIAL NUMBER'] ?? '').trim().isNotEmpty &&
          fields['SERIAL NUMBER'] != 'N/A')
        'SN ${fields['SERIAL NUMBER']}',
      if ((fields['IMEI'] ?? '').trim().isNotEmpty && fields['IMEI'] != 'N/A')
        'IMEI ${fields['IMEI']}',
      if ((fields['COUNTRY'] ?? '').trim().isNotEmpty &&
          fields['COUNTRY'] != 'N/A')
        _normalizeCountryValue(fields['COUNTRY']),
    ];
    return parts.join(' • ');
  }

  InvoiceDraftPrefill get _invoiceDraftPrefill => InvoiceDraftPrefill(
    itemName: _invoiceItemName,
    description: _invoiceDescription,
    condition: _riskLabel,
    imeiSerial:
        widget.report['imei']?.toString() ?? _allFieldsForPdf['IMEI'] ?? '',
    statusLabel: _invoiceStatusLabel,
    price: double.tryParse(
      _marketValueData?['amount']?.toString().trim() ?? '',
    ),
  );

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
    final deviceName = resolve([
      'model',
      'marketing_name',
      'model_description',
      'device_name',
      'product',
      'description',
    ]);

    fields.add(_DisplayField('DEVICE NAME', deviceName, fullWidth: true));

    fields.add(
      _DisplayField(
        'SERIAL NUMBER',
        resolve(['serial_number', 'serial', 'serialnumber']),
        fullWidth: true,
      ),
    );

    fields.add(
      _DisplayField(
        'IMEI',
        imei.isNotEmpty ? imei : resolve(['imei', 'imei_number']),
      ),
    );
    if (imei.isNotEmpty) usedKeys.addAll(['imei', 'imei_number']);

    fields.add(_DisplayField('IMEI 2', resolve(['imei2', 'imei2_number'])));

    fields.add(
      _DisplayField('MANUFACTURER', resolve(['manufacturer', 'brand'])),
    );

    fields.add(_DisplayField('MEID', resolve(['meid'])));

    // --- category-specific fields ---
    final cat = _category;

    if (cat == _DeviceCategory.apple) {
      fields.addAll([
        _DisplayField(
          'FIND MY IPHONE',
          resolve([
            'find_my_iphone',
            'fmi',
            'fmi_status',
            'findmyiphone',
            'find_my',
          ]),
        ),
        _DisplayField(
          'ICLOUD STATUS',
          resolve(['icloud_status', 'icloudstatus']),
        ),
        _DisplayField('ICLOUD LOCK', resolve(['icloud_lock', 'icloudlock'])),
        _DisplayField(
          'ACTIVATION STATUS',
          resolve([
            'activation_status',
            'activationstatus',
            'device_activation',
            'activation_policy',
            'activationpolicy',
          ]),
        ),
        _DisplayField(
          'BLACKLIST STATUS',
          resolve(['blacklist_status', 'blackliststatus', 'blacklist']),
        ),
        _DisplayField(
          'MDM STATUS',
          resolve(['mdm_lock', 'mdmlock', 'mdm_status', 'mdm']),
        ),
        _DisplayField(
          'BTU STATUS',
          resolve(['btu_status', 'btustatus', 'btu', 'carrier_btu']),
        ),
        _DisplayField(
          'SIM LOCK',
          resolve(['simlock', 'sim_lock', 'simlock_status', 'sim_lock_status']),
        ),
        _DisplayField(
          'LOCKED CARRIER',
          resolve(['locked_carrier', 'lockedcarrier', 'carrier']),
        ),
        _DisplayField(
          'WARRANTY STATUS',
          resolve(['warranty_status', 'warrantystatus', 'warranty']),
        ),
        _DisplayField(
          'LIMITED WARRANTY',
          resolve(['limited_warranty', 'limitedwarranty']),
        ),
        _DisplayField(
          'APPLECARE ELIGIBLE',
          resolve(['applecare_eligible', 'applecareeligible']),
        ),
        _DisplayField(
          'PURCHASE DATE',
          resolve(['purchase_date', 'purchasedate', 'estimated_purchase_date']),
        ),
        _DisplayField(
          'COVERAGE START',
          resolve([
            'coverage_start',
            'coveragestart',
            'repairs_and_service_coverage',
          ]),
        ),
        _DisplayField(
          'REPLACED DEVICE',
          resolve(['replaced_device', 'replaceddevice', 'replaced']),
        ),
        _DisplayField(
          'REPLACEMENT DEVICE',
          resolve(['replacement_device', 'replacementdevice']),
        ),
        _DisplayField(
          'REFURBISHED DEVICE',
          resolve(['refurbished_device', 'refurbisheddevice']),
        ),
        _DisplayField('DEMO UNIT', resolve(['demo_unit', 'demounit'])),
        _DisplayField(
          'LOANER DEVICE',
          resolve(['loaner_device', 'loanerdevice']),
        ),
        _DisplayField(
          'REGISTRATION STATUS',
          resolve(['registration_status', 'registrationstatus']),
        ),
        _DisplayField(
          'VALID PURCHASE DATE',
          resolve(['valid_purchase_date', 'validpurchasedate']),
        ),
        _DisplayField('TECH SUPPORT', resolve(['telephone_technical_support'])),
        _DisplayField(
          'TECH SUPPORT EXPIRES',
          resolve([
            'telephone_technical_support_expiration_date',
            'telephone_technical_support_expires_in',
          ]),
        ),
        _DisplayField(
          'REPAIR COVERAGE EXPIRES',
          resolve([
            'repairs_and_service_expiration_date',
            'repairs_and_service_expires_in',
          ]),
        ),
      ]);
    } else if (cat == _DeviceCategory.samsung) {
      fields.addAll([
        _DisplayField(
          'KNOX GUARD',
          resolve([
            'knox_guard',
            'knoxguard',
            'knox_status',
            'knox',
            'knox_lock',
          ]),
        ),
        _DisplayField(
          'ACTIVATION STATUS',
          resolve([
            'activation_status',
            'activationstatus',
            'device_activation',
          ]),
        ),
        _DisplayField(
          'BLACKLIST STATUS',
          resolve(['blacklist_status', 'blackliststatus', 'blacklist']),
        ),
        _DisplayField(
          'MDM STATUS',
          resolve(['mdm_lock', 'mdmlock', 'mdm_status', 'mdm']),
        ),
        _DisplayField(
          'BTU STATUS',
          resolve(['btu_status', 'btustatus', 'btu', 'carrier_btu']),
        ),
        _DisplayField(
          'SIM LOCK',
          resolve([
            'simlock',
            'sim_lock',
            'simlock_status',
            'sim_lock_status',
            'network_lock',
          ]),
        ),
        _DisplayField(
          'CARRIER',
          resolve(['carrier', 'locked_carrier', 'lockedcarrier', 'network']),
        ),
        _DisplayField(
          'WARRANTY STATUS',
          resolve(['warranty_status', 'warrantystatus', 'warranty']),
        ),
        _DisplayField(
          'PURCHASE DATE',
          resolve(['purchase_date', 'purchasedate']),
        ),
        _DisplayField(
          'OPERATING SYSTEM',
          resolve(['operating_system', 'operatingsystem', 'os']),
        ),
        _DisplayField(
          'COUNTRY',
          _normalizeCountryValue(resolve(['country', 'purchase_country'])),
        ),
        _DisplayField(
          'REPLACED DEVICE',
          resolve(['replaced_device', 'replaceddevice', 'replaced']),
        ),
      ]);
    } else {
      fields.addAll([
        _DisplayField(
          'ACTIVATION STATUS',
          resolve([
            'activation_status',
            'activationstatus',
            'device_activation',
          ]),
        ),
        _DisplayField(
          'BLACKLIST STATUS',
          resolve(['blacklist_status', 'blackliststatus', 'blacklist']),
        ),
        _DisplayField(
          'MDM STATUS',
          resolve(['mdm_lock', 'mdmlock', 'mdm_status', 'mdm']),
        ),
        _DisplayField(
          'KNOX GUARD',
          resolve(['knox_guard', 'knoxguard', 'knox_status', 'knox']),
        ),
        _DisplayField(
          'BTU STATUS',
          resolve(['btu_status', 'btustatus', 'btu', 'carrier_btu']),
        ),
        _DisplayField(
          'SIM LOCK',
          resolve([
            'simlock',
            'sim_lock',
            'simlock_status',
            'sim_lock_status',
            'network_lock',
          ]),
        ),
        _DisplayField(
          'CARRIER',
          resolve(['carrier', 'locked_carrier', 'lockedcarrier', 'network']),
        ),
        _DisplayField(
          'WARRANTY STATUS',
          resolve(['warranty_status', 'warrantystatus', 'warranty']),
        ),
        _DisplayField(
          'PURCHASE DATE',
          resolve(['purchase_date', 'purchasedate']),
        ),
        _DisplayField(
          'OPERATING SYSTEM',
          resolve(['operating_system', 'operatingsystem', 'os']),
        ),
        _DisplayField(
          'COUNTRY',
          _normalizeCountryValue(resolve(['country', 'purchase_country'])),
        ),
        _DisplayField(
          'REPLACED DEVICE',
          resolve(['replaced_device', 'replaceddevice', 'replaced']),
        ),
      ]);
    }

    // --- remaining provider keys not yet mapped ---
    final remaining = provider.entries
        .where((e) => !usedKeys.contains(e.key))
        .toList();

    for (final entry in remaining) {
      fields.add(_DisplayField(_snakeToLabel(entry.key), entry.value));
    }

    final marketValue = _formattedMarketValue;
    if (marketValue != null && marketValue.isNotEmpty) {
      fields.add(
        _DisplayField(
          'MARKET EXPECTED VALUE',
          marketValue,
          fullWidth: true,
          isMarketValue: true,
        ),
      );
    }

    return fields.where((f) => f.value != 'N/A').toList();
  }

  List<Widget> _buildFieldWidgets(List<_DisplayField> fields) {
    final widgets = <Widget>[];
    int i = 0;

    while (i < fields.length) {
      final field = fields[i];

      if (field.fullWidth) {
        if (field.isMarketValue) {
          widgets.add(
            _MarketValueCard(
              label: field.label,
              value: field.value,
              subtitle: _marketValueSubtitle,
            ),
          );
        } else {
          widgets.add(DeviceFieldFull(label: field.label, value: field.value));
        }
        widgets.add(SizedBox(height: 10));
        i++;
        continue;
      }

      if (i + 1 < fields.length && !fields[i + 1].fullWidth) {
        final next = fields[i + 1];
        widgets.add(
          DeviceFieldRow(
            leftLabel: field.label,
            leftValue: field.value,
            rightLabel: next.label,
            rightValue: next.value,
          ),
        );
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
    final icloud = (provider['icloud_lock'] ?? provider['icloudlock'] ?? '')
        .toLowerCase();
    if (blacklist.contains('clean') && icloud.contains('off')) return 0.96;
    if (blacklist.contains('clean')) return 0.85;
    if (blacklist.contains('blacklisted') || blacklist.contains('lost')) {
      return 0.15;
    }
    return 0.70;
  }

  String get _riskLabel {
    final data = _data;

    final riskMeter = data['riskMeter'] ?? data['riskAnalysis'];
    if (riskMeter is Map) {
      final label = riskMeter['label']?.toString().trim();
      if (label != null && label.isNotEmpty) return label;
    }

    final provider = _providerFields;
    final label = provider['risk_level'];
    if (label != null && label.isNotEmpty) return label;

    if (_riskScore >= 0.8) return 'Low Risk';
    if (_riskScore >= 0.5) return 'Medium Risk';
    return 'High Risk';
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

  String get _marketValueSubtitle {
    final currency = _marketValueData?['currency']?.toString().trim();
    if (currency != null && currency.isNotEmpty) {
      return 'Estimated $currency resale value';
    }
    return 'Estimated resale value';
  }

  static String _snakeToLabel(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'(^|\s)\w'), (m) => m.group(0)!.toUpperCase())
        .toUpperCase();
  }

  Rect? _shareOriginFor(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return null;

    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;

    final origin = box.localToGlobal(Offset.zero);
    final size = box.size;
    if (size.width <= 0 || size.height <= 0) return null;

    return Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height);
  }
}

class _DisplayField {
  final String label;
  final String value;
  final bool fullWidth;
  final bool isMarketValue;

  _DisplayField(
    this.label,
    this.value, {
    this.fullWidth = false,
    this.isMarketValue = false,
  });
}

class _MarketValueCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _MarketValueCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 38,
            height: 38,
            child: Center(child: _MarketValueTrendGlyph(color: accent)),
          ),
        ],
      ),
    );
  }
}

class _MarketValueTrendGlyph extends StatelessWidget {
  final Color color;

  const _MarketValueTrendGlyph({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Stack(
        children: [
          Positioned(
            left: 1,
            right: 1,
            bottom: 1,
            top: 1,
            child: CustomPaint(painter: _MarketTrendPainter(color)),
          ),
          Positioned(
            left: 5,
            bottom: 4,
            child: _MarketBar(height: 6, color: color),
          ),
          Positioned(
            left: 12,
            bottom: 4,
            child: _MarketBar(height: 11, color: color),
          ),
          Positioned(
            left: 19,
            bottom: 4,
            child: _MarketBar(height: 16, color: color),
          ),
          Positioned(
            left: 26,
            bottom: 4,
            child: _MarketBar(height: 21, color: color),
          ),
        ],
      ),
    );
  }
}

class _MarketBar extends StatelessWidget {
  final double height;
  final Color color;

  const _MarketBar({required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.5,
      height: height,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color, width: 1.35),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

class _MarketTrendPainter extends CustomPainter {
  final Color color;

  const _MarketTrendPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final axisPaint = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..strokeWidth = 1.35
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(2, size.height - 2),
      Offset(size.width - 2, size.height - 2),
      axisPaint,
    );
    canvas.drawLine(Offset(2, size.height - 2), Offset(2, 2), axisPaint);

    final trendPaint = Paint()
      ..color = color
      ..strokeWidth = 2.3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(7, 23)
      ..lineTo(14, 17)
      ..lineTo(20, 18)
      ..lineTo(28, 8);

    canvas.drawPath(path, trendPaint);
    canvas.drawLine(const Offset(28, 8), const Offset(24.8, 8.7), trendPaint);
    canvas.drawLine(const Offset(28, 8), const Offset(27.1, 11.4), trendPaint);
  }

  @override
  bool shouldRepaint(covariant _MarketTrendPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
