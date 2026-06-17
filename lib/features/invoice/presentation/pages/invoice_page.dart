import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../controller/invoice_data.dart';
import '../widgets/invoice_input_field.dart';
import '../widgets/invoice_product_item.dart';
import '../widgets/shop_info_card.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  int _tabIndex = 0;
  String? _selectedCustomer;
  String? _selectedPaymentType;
  bool _paymentTypeOpen = false;
  bool _customerDropOpen = false;
  final Set<int> _selectedProducts = {1};

  double get _totalAmount => _selectedProducts.fold(0, (sum, i) => sum + invoiceProducts[i].price);

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Create Invoice'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  _buildTabBar(),
                  const SizedBox(height: 22),
                  if (_tabIndex == 0) _buildCreateInvoiceTab(),
                  if (_tabIndex == 1) const Center(
                    child: Padding(padding: EdgeInsets.only(top: 60), child: Text('Purchase Invoice', style: TextStyle(color: AppColors.textSecondary, fontSize: 16))),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFF1A2840)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('Create Invoice', 0)),
          Expanded(child: _buildTab('Purchase Invoice', 1)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: isActive ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(50)),
        child: Center(
          child: Text(label, style: TextStyle(color: isActive ? Colors.black : AppColors.textSecondary, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.w400)),
        ),
      ),
    );
  }

  Widget _buildCreateInvoiceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Information', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _buildDropdown(_selectedCustomer, 'Choose a customer', _customerDropOpen, (v) => setState(() { _selectedCustomer = v; _customerDropOpen = false; }), () => setState(() => _customerDropOpen = !_customerDropOpen), customers),
        const SizedBox(height: 10),
        const Row(children: [Expanded(child: InvoiceInputField(hint: 'First Name')), SizedBox(width: 10), Expanded(child: InvoiceInputField(hint: 'Last Name'))]),
        const SizedBox(height: 10),
        const InvoiceInputField(hint: 'Customer Email'),
        const SizedBox(height: 10),
        const InvoiceInputField(hint: 'Customer Phone Number'),
        const SizedBox(height: 10),
        const InvoiceInputField(hint: 'Customer Billing Address'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildDropdown(_selectedPaymentType, 'Payment Type', _paymentTypeOpen, (v) => setState(() { _selectedPaymentType = v; _paymentTypeOpen = false; }), () => setState(() => _paymentTypeOpen = !_paymentTypeOpen), paymentTypes)),
          const SizedBox(width: 10),
          const Expanded(child: InvoiceInputField(hint: 'Already Paid')),
        ]),
        const SizedBox(height: 10),
        const InvoiceInputField(hint: 'Customer ID'),
        const SizedBox(height: 14),
        const ShopInfoCard(),
        const SizedBox(height: 24),
        const Text('Products', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _buildProductSearch(),
        const SizedBox(height: 12),
        ...invoiceProducts.asMap().entries.map((e) => InvoiceProductItem(
          product: e.value,
          isSelected: _selectedProducts.contains(e.key),
          onTap: () => setState(() => _selectedProducts.contains(e.key) ? _selectedProducts.remove(e.key) : _selectedProducts.add(e.key)),
        )),
      ],
    );
  }

  Widget _buildDropdown(String? selected, String hint, bool isOpen, void Function(String) onSelect, VoidCallback onToggle, List<String> items) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111A24),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.primary, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(selected ?? hint, style: TextStyle(color: selected != null ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 14)),
                const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 8),
              ...items.map((item) => GestureDetector(
                onTap: () => onSelect(item),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1A2840)))),
                  child: Text(item, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearch() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111A24),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
            child: const TextField(
              style: TextStyle(color: AppColors.primary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: TextStyle(color: AppColors.primary, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(50)),
          child: const Row(children: [
            Text('Category', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
          ]),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(color: Color(0xFF0D1A14), border: Border(top: BorderSide(color: Color(0xFF1A2840)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL AMOUNT DUE', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
                  const SizedBox(height: 2),
                  Text(
                    '£${_totalAmount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(0xFF111A24), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1A2840))),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.textPrimary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton(label: 'Send Invoice', onPressed: () {}),
        ],
      ),
    );
  }
}
