import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/shop_logo.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../profile/presentation/controller/profile_controller.dart';

class ShopInfoCard extends StatelessWidget {
  const ShopInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();

    return Obx(() {
      final shopName = profileCtrl.shopName.isNotEmpty
          ? profileCtrl.shopName
          : 'Your Shop';
      final ownerName = profileCtrl.fullName;
      final email = profileCtrl.email.isNotEmpty ? profileCtrl.email : 'N/A';
      final phone = profileCtrl.whatsappNumber.isNotEmpty
          ? profileCtrl.whatsappNumber
          : (profileCtrl.phone.isNotEmpty ? profileCtrl.phone : 'N/A');
      final address = profileCtrl.shopAddress.isNotEmpty
          ? profileCtrl.shopAddress
          : 'Store Address';
      final logoUrl = profileCtrl.imageUrl;

      return AppCard(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShopLogo(
              imageUrl: logoUrl,
              width: 96,
              height: 96,
              borderRadius: BorderRadius.circular(14),
              fallbackIconSize: 40,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (ownerName.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text(
                      ownerName,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  _info(Icons.email_outlined, email),
                  _info(Icons.phone_outlined, phone),
                  _info(Icons.location_on_outlined, address),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _info(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 13),
          SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
