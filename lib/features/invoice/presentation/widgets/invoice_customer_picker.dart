import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../../customer/domain/entities/customer.dart';

/// Display label used for a [Customer] across the invoice picker and the
/// callers that store the selection (e.g. as a text value in a form field).
String customerLabel(Customer customer) {
  final name = customer.fullName;
  if (name.isNotEmpty) return name;
  return customer.email.isNotEmpty ? customer.email : 'Customer';
}

/// A dropdown-style customer picker shared by the invoice create/purchase/
/// delivery tabs: a toggle field that expands into a selectable list of
/// customers.
class InvoiceCustomerPicker extends StatelessWidget {
  final List<Customer> customers;
  final String? selected;
  final bool isOpen;
  final bool isLoading;
  final VoidCallback onToggle;
  final ValueChanged<Customer> onSelect;
  final double dropdownLoaderSize;

  const InvoiceCustomerPicker({
    super.key,
    required this.customers,
    required this.selected,
    required this.isOpen,
    required this.isLoading,
    required this.onToggle,
    required this.onSelect,
    this.dropdownLoaderSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.primary.withValues(
                alpha: AppColors.isDark ? 0.6 : 0.72,
              ),
              width: 1.2,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(26),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isLoading
                          ? 'Loading customers...'
                          : (selected ?? 'Choose a customer'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected != null && !isLoading
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isOpen) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: _buildMenu(),
          ),
        ],
      ],
    );
  }

  Widget _buildMenu() {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: dropdownLoaderSize,
            height: dropdownLoaderSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (customers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No customers found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        children: customers.map((customer) {
          final label = customerLabel(customer);
          final isSelected = selected == label;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelect(customer),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.fieldBackground
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check, color: AppColors.primary, size: 18),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
