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
  const DeviceReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Device Report'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  const DeviceFieldFull(
                    label: 'DEVICE NAME',
                    value: 'iPhone SE 1st Gen 2016',
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldFull(
                    label: 'DEVICE DESCRIPTION',
                    value: 'OBS,IPHONE SE,HB,16GB,GRAY',
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldFull(
                    label: 'SERIAL NUMBER',
                    value: 'HH3HJ0TJ0D84',
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldRow(
                    leftLabel: 'SERVICE ID',
                    leftValue: '354957736904965',
                    rightLabel: 'MANUFACTURER',
                    rightValue: '354957736789788',
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldRow(
                    leftLabel: 'IMEI',
                    leftValue: '354957736904965',
                    rightLabel: 'IMEI 2',
                    rightValue: '354957736789788',
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldRow(
                    leftLabel: 'FIND MY IPHONE',
                    leftValue: 'No',
                    rightLabel: 'ICLOUD STATUS',
                    rightValue: 'Clean',
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldRow(
                    leftLabel: 'ICLOUD LOCK',
                    leftValue: '354957736904965',
                    rightLabel: 'SIM LOCK',
                    rightValue: '354957736789788',
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldRow(
                    leftLabel: 'MDM LOCK',
                    leftValue: 'No',
                    rightLabel: 'SIM POLICY',
                    rightValue: 'Yes',
                  ),
                  const SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'ACTIVATION POLICY',
                    leftValue: 'Yes',
                    rightLabel: 'LOCKED CARRIER',
                    rightValue: 'Clean',
                    leftValueColor: AppColors.primary,
                    rightValueColor: const Color(0xFF4DB8FF),
                  ),
                  const SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'WARRANTY',
                    leftValue: 'Yes',
                    rightLabel: 'LIMITED WARRANTY',
                    rightValue: 'No',
                    leftValueColor: AppColors.primary,
                    rightValueColor: const Color(0xFF4DB8FF),
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldRow(
                    leftLabel: 'PURCHASE DATE',
                    leftValue: 'N/A',
                    rightLabel: 'COVERAGE START',
                    rightValue: 'N/A',
                    leftValueColor: AppColors.primary,
                    rightValueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  const DeviceFieldRow(
                    leftLabel: 'REPLACED BY APPLE',
                    leftValue: 'Yes',
                    rightLabel: 'PURCHASE DATE',
                    rightValue: 'N/A',
                    leftValueColor: AppColors.primary,
                    rightValueColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const AiRiskCard(
                    percentage: 0.96,
                    description:
                        'This device shows excellent health, verified original components, low fraud probability, and high resale potential. Recommended for resale, trade-in, or direct customer purchase.',
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Download PDF Certificate',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'PDF certificate export is coming soon.',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  AppOutlinedButton(
                    label: 'Create Smart Invoice',
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppGroundView(initialIndex: 4),
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
}
