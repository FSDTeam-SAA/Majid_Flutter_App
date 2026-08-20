import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../invoice/presentation/widgets/invoice_input_field.dart';
import '../controller/staff_controller.dart';

Future<bool?> showAddStaffSheet(
  BuildContext context,
  StaffController controller,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AddStaffSheet(controller: controller),
  );
}

class AddStaffSheet extends StatefulWidget {
  final StaffController controller;

  const AddStaffSheet({super.key, required this.controller});

  @override
  State<AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<AddStaffSheet> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _isValidEmail =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_emailCtrl.text.trim());

  Future<void> _submit() async {
    setState(() => _errorMessage = '');

    if (_firstNameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a first name.');
      return;
    }
    if (!_isValidEmail) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (_passwordCtrl.text.trim().length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    try {
      await widget.controller.createStaff(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on DioException catch (e) {
      debugPrint(
        'createStaff DioException: ${e.type} status=${e.response?.statusCode} data=${e.response?.data}',
      );
      final serverMessage = e.response?.data is Map
          ? e.response?.data['message']?.toString()
          : null;
      setState(
        () => _errorMessage =
            serverMessage ??
            (e.type == DioExceptionType.connectionTimeout ||
                    e.type == DioExceptionType.receiveTimeout
                ? 'Server is taking too long to respond. Please try again.'
                : e.type == DioExceptionType.connectionError
                ? 'Could not connect to the server. Check your internet connection.'
                : 'Failed to create staff member. Please try again.'),
      );
    } catch (e) {
      debugPrint('createStaff error: $e');
      setState(
        () => _errorMessage = e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Failed to create staff member. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Add Staff Member',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create a staff login. The role will be saved as staff.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: InvoiceInputField(
                        hint: 'First Name',
                        controller: _firstNameCtrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InvoiceInputField(
                        hint: 'Last Name',
                        controller: _lastNameCtrl,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InvoiceInputField(
                  hint: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                InvoiceInputField(
                  hint: 'Phone',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _buildPasswordField(),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _errorMessage,
                    style: TextStyle(
                      color: AppColors.dangerColor,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Obx(() {
                  final isCreating = widget.controller.isCreating.value;
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isCreating
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(color: AppColors.fieldBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          label: isCreating ? 'Creating...' : 'Create Staff',
                          isLoading: isCreating,
                          onPressed: isCreating ? null : _submit,
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: AppColors.primary.withValues(
            alpha: AppColors.isDark ? 0.6 : 0.72,
          ),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          isDense: true,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }
}
