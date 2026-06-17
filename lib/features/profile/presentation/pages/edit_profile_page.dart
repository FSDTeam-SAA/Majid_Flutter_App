import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _firstNameCtrl = TextEditingController(text: 'Sarah');
  final _lastNameCtrl  = TextEditingController(text: 'Jenkins');
  final _emailCtrl     = TextEditingController(text: 'Sarah.J@Imoscan.App');
  final _phoneCtrl     = TextEditingController();
  final _whatsappCtrl  = TextEditingController();
  final _shopNameCtrl  = TextEditingController();
  final _addressCtrl   = TextEditingController();

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _hideCurrentPass = true;
  bool _hideNewPass     = true;
  bool _hideConfirmPass = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1F2D), Color(0xFF060E0B)],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPersonalSection(),
                      const SizedBox(height: 16),
                      _buildPasswordSection(),
                      const SizedBox(height: 24),
                      _buildSaveBtn(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 16),
            ),
          ),
          const Expanded(
            child: Text(
              'Edit Profile',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return _SectionCard(
      title: 'Personal & Shop Information',
      children: [
        Row(
          children: [
            Expanded(child: _AppField(controller: _firstNameCtrl, hint: 'First Name')),
            const SizedBox(width: 12),
            Expanded(child: _AppField(controller: _lastNameCtrl, hint: 'Last Name')),
          ],
        ),
        _AppField(controller: _emailCtrl, hint: 'Email', keyboardType: TextInputType.emailAddress),
        _AppField(controller: _phoneCtrl, hint: 'Phone Number', keyboardType: TextInputType.phone),
        _AppField(controller: _whatsappCtrl, hint: 'Whatsapp Number', keyboardType: TextInputType.phone),
        _AppField(controller: _shopNameCtrl, hint: 'Shop Name'),
        _AppField(controller: _addressCtrl, hint: 'Shop Address'),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return _SectionCard(
      title: 'Change Password',
      subtitle: 'Secure your account',
      children: [
        _AppField(
          controller: _currentPassCtrl,
          hint: 'Current Password',
          obscure: _hideCurrentPass,
          suffix: IconButton(
            icon: Icon(_hideCurrentPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => setState(() => _hideCurrentPass = !_hideCurrentPass),
          ),
        ),
        _AppField(
          controller: _newPassCtrl,
          hint: 'New Password',
          obscure: _hideNewPass,
          suffix: IconButton(
            icon: Icon(_hideNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => setState(() => _hideNewPass = !_hideNewPass),
          ),
        ),
        _AppField(
          controller: _confirmPassCtrl,
          hint: 'Confirm New Password',
          obscure: _hideConfirmPass,
          suffix: IconButton(
            icon: Icon(_hideConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary, size: 20),
            onPressed: () => setState(() => _hideConfirmPass = !_hideConfirmPass),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveBtn() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const _SectionCard({required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: child,
          )),
        ],
      ),
    );
  }
}

class _AppField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _AppField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        filled: true,
        fillColor: AppColors.fieldBackground,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
