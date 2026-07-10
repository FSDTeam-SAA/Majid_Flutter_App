import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/entities/customer.dart';
import '../controller/customer_controller.dart';
import '../widgets/add_customer_sheet.dart';
import '../widgets/customer_card.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  late final CustomerController _controller;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<CustomerController>() ? Get.find<CustomerController>() : Get.put(CustomerController());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openAddCustomerSheet({Customer? existing}) async {
    await showAddCustomerSheet(context, _controller, existing: existing);
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Remove customer?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to remove ${customer.fullName.isEmpty ? customer.email : customer.fullName}?',
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
      await _controller.deleteCustomer(customer.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'Customers',
            showBackButton: true,
            trailing: GestureDetector(
              onTap: () => _openAddCustomerSheet(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Icon(Icons.add_rounded, color: AppColors.surfaceForeground, size: 22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.fieldBackground,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.primary.withValues(alpha: AppColors.isDark ? 0.6 : 0.72), width: 1.2),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _controller.setSearchQuery,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search name, email, phone...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
                        OutlinedButton(onPressed: _controller.fetchCustomers, child: const Text('Retry')),
                      ],
                    ),
                  ),
                );
              }

              final customers = _controller.filteredCustomers;

              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.cardBackground,
                onRefresh: _controller.fetchCustomers,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                  children: [
                    Text(
                      '${customers.length} customers found',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    if (customers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text('No customers found.', style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ...customers.map(
                        (customer) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CustomerCard(
                            customer: customer,
                            onEdit: () => _openAddCustomerSheet(existing: customer),
                            onDelete: () => _confirmDelete(customer),
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
