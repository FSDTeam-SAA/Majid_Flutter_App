import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../invoice/presentation/widgets/invoice_input_field.dart';
import '../../domain/entities/customer.dart';
import '../controller/customer_controller.dart';

Future<bool?> showAddCustomerSheet(
  BuildContext context,
  CustomerController controller, {
  Customer? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        AddCustomerSheet(controller: controller, existing: existing),
  );
}

class AddCustomerSheet extends StatefulWidget {
  final CustomerController controller;
  final Customer? existing;

  const AddCustomerSheet({super.key, required this.controller, this.existing});

  @override
  State<AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<AddCustomerSheet> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  String _errorMessage = '';

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _firstNameCtrl = TextEditingController(text: existing?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: existing?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    _emailCtrl = TextEditingController(text: existing?.email ?? '');
    _addressCtrl = TextEditingController(text: existing?.address ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = '');

    if (_firstNameCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a first name.');
      return;
    }

    try {
      final success = _isEditing
          ? await widget.controller.updateCustomer(
              id: widget.existing!.id,
              firstName: _firstNameCtrl.text.trim(),
              lastName: _lastNameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
            )
          : await widget.controller.createCustomer(
              firstName: _firstNameCtrl.text.trim(),
              lastName: _lastNameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              phone: _phoneCtrl.text.trim(),
              address: _addressCtrl.text.trim(),
            );
      if (mounted && success) Navigator.pop(context, true);
    } catch (e) {
      setState(
        () => _errorMessage = 'Failed to save customer. Please try again.',
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
                  _isEditing ? 'Edit Customer' : 'Add Customer',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep customer details handy for invoices and follow-ups.',
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
                        hint: 'First Name *',
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
                  hint: 'Phone',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                InvoiceInputField(
                  hint: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                InvoiceInputField(hint: 'Address', controller: _addressCtrl),
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
                  final isSaving = widget.controller.isSaving.value;
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSaving
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
                          label: isSaving ? 'Saving...' : 'Save',
                          isLoading: isSaving,
                          onPressed: isSaving ? null : _submit,
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
}
