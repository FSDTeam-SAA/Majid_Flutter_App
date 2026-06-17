import 'package:flutter/material.dart';
import '../utils/colors.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? imagePath;

  const UserAvatar({super.key, this.size = 40, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.fieldBorder, width: 1.5),
        image: DecorationImage(
          image: AssetImage(imagePath ?? 'assets/images/qrcode.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
