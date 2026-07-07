import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/profile/presentation/controller/profile_controller.dart';
import '../../features/profile/presentation/pages/profile_page_view.dart';
import '../utils/colors.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? imagePath;

  const UserAvatar({super.key, this.size = 40, this.imagePath});

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.isRegistered<ProfileController>() ? Get.find<ProfileController>() : null;

    if (profileCtrl == null) {
      return _wrapWithTap(_buildFallbackAvatar());
    }

    return Obx(() {
      final imageUrl = imagePath ?? profileCtrl.imageUrl;
      return _wrapWithTap(
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.fieldBorder, width: 1.5),
            color: AppColors.cardBackground,
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildFallbackContent())
              : _buildFallbackContent(),
        ),
      );
    });
  }

  Widget _wrapWithTap(Widget child) {
    return GestureDetector(onTap: () => Get.to(() => const ProfilePageView()), child: child);
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.fieldBorder, width: 1.5),
        color: AppColors.cardBackground,
      ),
      child: _buildFallbackContent(),
    );
  }

  Widget _buildFallbackContent() {
    return Icon(Icons.person, color: AppColors.textPrimary, size: size * 0.52);
  }
}
