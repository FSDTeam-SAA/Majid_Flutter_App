import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/info_field.dart';
import '../controller/profile_controller.dart';

class ShopkeeperIdCardPage extends StatefulWidget {
  const ShopkeeperIdCardPage({super.key});

  @override
  State<ShopkeeperIdCardPage> createState() => _ShopkeeperIdCardPageState();
}

class _ShopkeeperIdCardPageState extends State<ShopkeeperIdCardPage> {
  final _qrKey = GlobalKey();
  bool _isSaving = false;

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
                      _buildQrBox(shortId),
                      SizedBox(height: 14),
                      AppButton(
                        label: _isSaving ? 'Saving...' : 'Download QR',
                        onPressed: _isSaving ? null : () => _downloadQr(shortId),
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

  Widget _buildQrBox(String shopkeeperId) {
    return RepaintBoundary(
      key: _qrKey,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cardBackground,
              AppColors.fieldBackground,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'SCAN TO VERIFY',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: shopkeeperId,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF1A1A2E),
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
            SizedBox(height: 14),
            Text(
              shopkeeperId,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadQr(String shopkeeperId) async {
    setState(() => _isSaving = true);
    try {
      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/qr_$shopkeeperId.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'Shopkeeper QR: $shopkeeperId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save QR code.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
