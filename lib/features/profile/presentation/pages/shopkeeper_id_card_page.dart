import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/info_field.dart';

class ShopkeeperIdCardPage extends StatelessWidget {
  const ShopkeeperIdCardPage({super.key});

  static const _shopkeeperId = 'IMS-MM-F7244';

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Shopkeeper Id Card'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoField(label: 'NAME', value: 'Muhammad Majid'),
                    const SizedBox(height: 20),
                    _buildIdBox(context),
                    const SizedBox(height: 20),
                    const InfoField(
                      label: 'EMAIL:',
                      value: 'shopkeeper2@gmail.com',
                    ),
                    const SizedBox(height: 14),
                    const InfoField(label: 'PHONE:', value: '07777787771'),
                    const SizedBox(height: 14),
                    const InfoField(
                      label: 'SHOP NAME:',
                      value: 'Mobile Kit Distribution',
                    ),
                    const SizedBox(height: 14),
                    const InfoField(
                      label: 'ADDRESS:',
                      value: 'Unit 22 MKD the liberty shopping centre',
                    ),
                    const SizedBox(height: 24),
                    _buildQrBox(),
                    const SizedBox(height: 14),
                    AppButton(
                      label: 'Download QR',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR download is coming soon.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1520),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2840)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: InfoField(label: 'SHOPKEEPER ID', value: _shopkeeperId),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _shopkeeperId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID copied!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2840),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.copy_outlined,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrBox() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/images/qrcode.jpg', fit: BoxFit.contain),
      ),
    );
  }
}
