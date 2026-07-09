import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/utils/colors.dart';
import '../../domain/entities/staff_member.dart';
import '../controller/staff_controller.dart';
import '../widgets/add_staff_sheet.dart';
import '../widgets/staff_list_item.dart';
import '../widgets/staff_stat_card.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  late final StaffController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<StaffController>() ? Get.find<StaffController>() : Get.put(StaffController());
  }

  Future<void> _openAddStaffSheet() async {
    final created = await showAddStaffSheet(context, _controller);
    if (created == true && mounted) {
      Get.snackbar(
        'Staff added',
        'The staff member has been created successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.cardBackground,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      );
    }
  }

  Future<void> _confirmDelete(StaffMember staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Remove staff member?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to remove ${staff.fullName}?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove', style: TextStyle(color: AppColors.dangerColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.deleteStaff(staff.id);
    }
  }

  void _showStaffDetails(StaffMember staff) {
    final displayName = staff.fullName.isEmpty ? staff.email : staff.fullName;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final joined = staff.createdAt.toLocal();
    final joinedText =
        '${joined.day.toString().padLeft(2, '0')}/${joined.month.toString().padLeft(2, '0')}/${joined.year} '
        '${joined.hour.toString().padLeft(2, '0')}:${joined.minute.toString().padLeft(2, '0')}';

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 18),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.fieldBorder),
            boxShadow: [BoxShadow(color: AppColors.overlayShadow, blurRadius: 24, offset: const Offset(0, 12))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Text(
                  initial,
                  style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                staff.jobRole,
                style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.fieldBackground, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  children: [
                    _detailRow(Icons.email_outlined, 'Email', staff.email),
                    if (staff.phone.isNotEmpty) ...[
                      Divider(height: 1, color: AppColors.fieldBorder),
                      _detailRow(Icons.phone_outlined, 'Phone', staff.phone),
                    ],
                    Divider(height: 1, color: AppColors.fieldBorder),
                    _detailRow(Icons.event_outlined, 'Joined', joinedText),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surfaceForeground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'Staff Management',
            showBackButton: true,
            trailing: GestureDetector(
              onTap: _openAddStaffSheet,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_add_alt_1_rounded, color: AppColors.surfaceForeground, size: 18),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (_controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _controller.errorMessage.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _controller.fetchStaff, child: const Text('Retry')),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.cardBackground,
                onRefresh: _controller.fetchStaff,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                  children: [
                    Text(
                      'Add and manage staff members for your shop account.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: StaffStatCard(
                            label: 'TOTAL STAFF',
                            value: _controller.totalStaff,
                            icon: Icons.groups_2_outlined,
                            accentColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StaffStatCard(
                            label: 'VERIFIED',
                            value: _controller.verifiedCount,
                            icon: Icons.verified_outlined,
                            accentColor: const Color(0xFF34C759),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StaffStatCard(
                            label: 'PENDING',
                            value: _controller.pendingCount,
                            icon: Icons.hourglass_empty_rounded,
                            accentColor: const Color(0xFFFF9F43),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Staff Members',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    if (_controller.staffList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text('No staff members found.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ..._controller.staffList.map(
                        (staff) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: StaffListItem(
                            staff: staff,
                            onDelete: () => _confirmDelete(staff),
                            onTap: () => _showStaffDetails(staff),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
