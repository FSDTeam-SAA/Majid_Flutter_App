import 'package:flutter/material.dart';
import '../../../../app_ground_view.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_outlined_button.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../widgets/ai_risk_card.dart';
import '../widgets/device_field_card.dart';

class DeviceReportPage extends StatelessWidget {
  final Map<String, dynamic> report;

  const DeviceReportPage({super.key, this.report = const {}});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Device Report'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  DeviceFieldFull(label: 'DEVICE NAME', value: _field('Model')),
                  SizedBox(height: 10),
                  DeviceFieldFull(
                    label: 'DEVICE DESCRIPTION',
                    value: _field('Device') == 'N/A'
                        ? _field('Description')
                        : _field('Device'),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldFull(
                    label: 'SERIAL NUMBER',
                    value: _field('Serial'),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'SERVICE ID',
                    leftValue: report['serviceId']?.toString() ?? 'N/A',
                    rightLabel: 'MANUFACTURER',
                    rightValue: _field('Manufacturer'),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'IMEI',
                    leftValue: report['imei']?.toString() ?? _field('IMEI'),
                    rightLabel: 'IMEI 2',
                    rightValue: _field('IMEI2'),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'FIND MY IPHONE',
                    leftValue: _field('Find My iPhone'),
                    rightLabel: 'ICLOUD STATUS',
                    rightValue: _field('iCloud Status'),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'ICLOUD LOCK',
                    leftValue: _field('iCloud Lock'),
                    rightLabel: 'SIM LOCK',
                    rightValue: _field('SIM Lock'),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'MDM LOCK',
                    leftValue: _field('MDM Lock'),
                    rightLabel: 'SIM POLICY',
                    rightValue: _field('SIM Policy'),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'ACTIVATION POLICY',
                    leftValue: _field('Activation Policy'),
                    rightLabel: 'LOCKED CARRIER',
                    rightValue: _field('Locked Carrier'),
                    leftValueColor: AppColors.primary,
                    rightValueColor: Color(0xFF4DB8FF),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'WARRANTY',
                    leftValue: _field('Warranty'),
                    rightLabel: 'LIMITED WARRANTY',
                    rightValue: _field('Limited Warranty'),
                    leftValueColor: AppColors.primary,
                    rightValueColor: Color(0xFF4DB8FF),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'PURCHASE DATE',
                    leftValue: _field('Purchase Date'),
                    rightLabel: 'COVERAGE START',
                    rightValue: _field('Coverage Start'),
                    leftValueColor: AppColors.primary,
                    rightValueColor: AppColors.primary,
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'REPLACED BY APPLE',
                    leftValue: _field('Replaced'),
                    rightLabel: 'BLACKLIST STATUS',
                    rightValue: _field('Blacklist Status'),
                    leftValueColor: AppColors.primary,
                    rightValueColor: AppColors.primary,
                  ),
                  SizedBox(height: 12),
                  AiRiskCard(
                    percentage: _riskScore,
                    description: _riskDescription,
                  ),
                  SizedBox(height: 16),
                  AppButton(
                    label: 'Download PDF Certificate',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'PDF certificate export is coming soon.',
                          ),
                        ),
                      );
                    },
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> get _data {
    final data = report['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return report;
  }

  double get _riskScore {
    final data = _data;
    final providerData = data['parsedProviderData'] ?? data['providerData'];

    for (final source in [providerData, data]) {
      if (source is! Map) continue;
      for (final key in ['riskScore', 'risk_score', 'score', 'healthScore']) {
        final val = source[key];
        if (val is num) return val.toDouble().clamp(0.0, 1.0);
      }
    }

    final blacklist = _field('Blacklist Status').toLowerCase();
    final icloud = _field('iCloud Lock').toLowerCase();
    if (blacklist.contains('clean') && icloud.contains('off')) return 0.96;
    if (blacklist.contains('clean')) return 0.85;
    if (blacklist.contains('blacklisted') || blacklist.contains('lost')) return 0.15;
    return 0.70;
  }

  String get _riskDescription {
    final data = _data;
    final providerData = data['parsedProviderData'] ?? data['providerData'];
    if (providerData is Map) {
      final desc = providerData['riskDescription'] ?? providerData['risk_description'];
      if (desc != null && desc.toString().trim().isNotEmpty) return desc.toString();
    }

    if (_riskScore >= 0.8) {
      return 'This device shows excellent health, verified original components, low fraud probability, and high resale potential. Recommended for resale, trade-in, or direct customer purchase.';
    } else if (_riskScore >= 0.5) {
      return 'This device shows moderate risk indicators. Some checks could not be fully verified. Proceed with caution and consider additional verification.';
    } else {
      return 'This device shows high risk indicators. It may be blacklisted, lost, or stolen. Not recommended for purchase or resale without further investigation.';
    }
  }

  String _field(String key) {
    final data = _data;
    final providerData = data['parsedProviderData'] ?? data['providerData'];
    if (providerData is Map) {
      final direct = providerData[key] ?? providerData[key.toLowerCase()];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return direct.toString();
      }
    }
    final direct = data[key] ?? data[key.toLowerCase()];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }
    return 'N/A';
  }
}
