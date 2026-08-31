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
/// delivery tabs: a toggle field that expands into a searchable list of
/// customers.
class InvoiceCustomerPicker extends StatelessWidget {
  final List<Customer> customers;
  final String? selected;
  final bool isOpen;
  final bool isLoading;
  final TextEditingController searchController;
  final VoidCallback onToggle;
  final ValueChanged<Customer> onSelect;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onAddCustomer;
  final double dropdownLoaderSize;

  const InvoiceCustomerPicker({
    super.key,
    required this.customers,
    required this.selected,
    required this.isOpen,
    required this.isLoading,
    required this.searchController,
    required this.onToggle,
    required this.onSelect,
    this.onSearchChanged,
    this.onAddCustomer,
    this.dropdownLoaderSize = 22,
  });

  List<Customer> get _filteredCustomers {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) return customers;

    return customers.where((customer) {
      final haystack = [
        customer.fullName,
        customer.email,
        customer.phone,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

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

    final filteredCustomers = _filteredCustomers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildCustomerResults(filteredCustomers),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: TextField(
        controller: searchController,
        onChanged: onSearchChanged,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search name, email, phone...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    searchController.clear();
                    onSearchChanged?.call('');
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerResults(List<Customer> filteredCustomers) {
    if (filteredCustomers.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No customers found',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ),
          if (onAddCustomer != null) _buildAddCustomerButton(),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: filteredCustomers.length,
            itemBuilder: (context, index) {
              final customer = filteredCustomers[index];
              final label = customerLabel(customer);
              final isSelected = selected == label;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(customer),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
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
            },
          ),
        ),
        if (onAddCustomer != null) ...[
          const SizedBox(height: 6),
          _buildAddCustomerButton(),
        ],
      ],
    );
  }

  Widget _buildAddCustomerButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onAddCustomer,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'Add new customer',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
