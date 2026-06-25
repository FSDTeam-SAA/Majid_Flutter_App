import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/info_field.dart';
import '../controller/profile_controller.dart';

class ShopkeeperIdCardPage extends StatelessWidget {
  const ShopkeeperIdCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();

    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Shopkeeper Id Card'),
          Expanded(
            child: Obx(() {
              final data = profileCtrl.profileData;
              final name = profileCtrl.fullName;
              final email = profileCtrl.email;
              final phone = data['whatsappNumber'] ?? data['phone'] ?? '';
              final shop = data['shopName'] ?? '';
              final address = data['shopAddress'] ?? '';
              final id = data['_id'] ?? '';
              final shortId = id.length > 8
                  ? 'IMS-${id.substring(id.length - 8).toUpperCase()}'
                  : id;

              return SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: AppCard(
                  padding: EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoField(
                        label: 'NAME',
                        value: name.isNotEmpty ? name : 'N/A',
                      ),
                      SizedBox(height: 20),
                      _buildIdBox(context, shortId),
                      SizedBox(height: 20),
                      InfoField(
                        label: 'EMAIL:',
                        value: email.isNotEmpty ? email : 'N/A',
                      ),
                      SizedBox(height: 14),
                      InfoField(
                        label: 'PHONE:',
                        value: phone.isNotEmpty ? phone : 'N/A',
                      ),
                      SizedBox(height: 14),
                      InfoField(
                        label: 'SHOP NAME:',
                        value: shop.isNotEmpty ? shop : 'N/A',
                      ),
                      SizedBox(height: 14),
                      InfoField(
                        label: 'ADDRESS:',
                        value: address.isNotEmpty ? address : 'N/A',
                      ),
                      SizedBox(height: 24),
                      _buildQrBox(),
                      SizedBox(height: 14),
                      AppButton(
                        label: 'Download QR',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('QR download is coming soon.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildIdBox(BuildContext context, String shopkeeperId) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InfoField(label: 'SHOPKEEPER ID', value: shopkeeperId),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: shopkeeperId));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ID copied!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.fieldBorder,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
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
