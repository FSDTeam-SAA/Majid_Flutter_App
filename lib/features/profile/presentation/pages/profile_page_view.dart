import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../widgets/profile_menu_item.dart';
import 'shopkeeper_id_card_page.dart';
import 'edit_profile_page.dart';
import 'payment_history_page.dart';
import 'upgrade_plan_page.dart';
import 'business_health_score_page.dart';

class ProfilePageView extends StatelessWidget {
  const ProfilePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Profile'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildAvatar(),
                  const SizedBox(height: 14),
                  const Text('Sarah Jenkins', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('sarah.j@imoscan.app', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 14),
                  _buildCreditsRow(),
                  const SizedBox(height: 32),
                  _buildSection('Account', [
                    ('Shopkeeper Id Card', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopkeeperIdCardPage()))),
                    ('Account Information', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()))),
                    ('Business Health Score', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessHealthScorePage()))),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Subscription', [
                    ('Upgrade Plan', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradePlanPage()))),
                    ('Payment History', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryPage()))),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Support', [
                    ('Help Center', () {}),
                    ('About App', () {}),
                  ]),
                  const SizedBox(height: 32),
                  _buildLogoutBtn(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 96, height: 96,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.fieldBorder, width: 2)),
      child: ClipOval(
        child: Image.network('https://i.pravatar.cc/200', fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.person, color: AppColors.textPrimary, size: 50)),
      ),
    );
  }

  Widget _buildCreditsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Your credits: 1,250', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(20)),
          child: const Text('Upgrade', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<(String, VoidCallback)> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ProfileMenuItem(label: item.$1, onTap: item.$2),
        )),
      ],
    );
  }

  Widget _buildLogoutBtn() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE05A5A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('Log out', style: TextStyle(color: Color(0xFFE05A5A), fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
