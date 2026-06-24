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
          AppHeader(title: 'Device Report'),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Column(
                children: [
                  DeviceFieldFull(
                    label: 'DEVICE NAME',
                    value: 'iPhone SE 1st Gen 2016',
                  ),
                  SizedBox(height: 10),
                  DeviceFieldFull(
                    label: 'DEVICE DESCRIPTION',
                    value: 'OBS,IPHONE SE,HB,16GB,GRAY',
                  ),
                  SizedBox(height: 10),
                  DeviceFieldFull(
                    label: 'SERIAL NUMBER',
                    value: 'HH3HJ0TJ0D84',
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'SERVICE ID',
                    leftValue: '354957736904965',
                    rightLabel: 'MANUFACTURER',
                    rightValue: '354957736789788',
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'IMEI',
                    leftValue: '354957736904965',
                    rightLabel: 'IMEI 2',
                    rightValue: '354957736789788',
                  ),
                  SizedBox(height: 10),
                  DeviceFieldRow(
                    leftLabel: 'FIND MY IPHONE',
                    leftValue: 'No',
                    rightLabel: 'ICLOUD STATUS',
                    rightValue: 'Clean',
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
}
