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
                    leftValue: '354957736904965',
                    rightLabel: 'SIM LOCK',
                    rightValue: '354957736789788',
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'MDM LOCK',
                    leftValue: 'No',
                    rightLabel: 'SIM POLICY',
                    rightValue: 'Yes',
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'ACTIVATION POLICY',
                    leftValue: 'Yes',
                    rightLabel: 'LOCKED CARRIER',
                    rightValue: 'Clean',
                    leftValueColor: AppColors.primary,
                    rightValueColor: Color(0xFF4DB8FF),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'WARRANTY',
                    leftValue: 'Yes',
                    rightLabel: 'LIMITED WARRANTY',
                    rightValue: 'No',
                    leftValueColor: AppColors.primary,
                    rightValueColor: Color(0xFF4DB8FF),
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'PURCHASE DATE',
                    leftValue: 'N/A',
                    rightLabel: 'COVERAGE START',
                    rightValue: 'N/A',
                    leftValueColor: AppColors.primary,
                    rightValueColor: AppColors.primary,
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'REPLACED BY APPLE',
                    leftValue: 'Yes',
                    rightLabel: 'PURCHASE DATE',
                    rightValue: 'N/A',
                    leftValueColor: AppColors.primary,
                    rightValueColor: AppColors.primary,
                  ),
                  SizedBox(height: 12),
                  AiRiskCard(
                    percentage: 0.96,
                    description:
                        'This device shows excellent health, verified original components, low fraud probability, and high resale potential. Recommended for resale, trade-in, or direct customer purchase.',
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
