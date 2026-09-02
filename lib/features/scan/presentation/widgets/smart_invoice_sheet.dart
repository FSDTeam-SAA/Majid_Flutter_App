import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/colors.dart';
import '../../../customer/domain/entities/customer.dart';
import '../../domain/entities/smart_invoice_data.dart';
import '../utils/country_list.dart';
import 'searchable_picker_sheet.dart';

/// The website's Smart Invoice dialog: it asks only for what the scan cannot
/// supply, then generates the invoice.
Future<SmartInvoiceCustomer?> showSmartInvoiceSheet({
  required BuildContext context,
  required double? suggestedAmount,
  required String suggestedCurrency,
  List<Customer> existingCustomers = const [],
}) {
  return showModalBottomSheet<SmartInvoiceCustomer>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _SmartInvoiceSheet(
      suggestedAmount: suggestedAmount,
      suggestedCurrency: suggestedCurrency,
      existingCustomers: existingCustomers,
    ),
  );
}

class _SmartInvoiceSheet extends StatefulWidget {
  final double? suggestedAmount;
  final String suggestedCurrency;
  final List<Customer> existingCustomers;

  const _SmartInvoiceSheet({
    required this.suggestedAmount,
    required this.suggestedCurrency,
    required this.existingCustomers,
  });

  @override
  State<_SmartInvoiceSheet> createState() => _SmartInvoiceSheetState();
}

class _SmartInvoiceSheetState extends State<_SmartInvoiceSheet> {
  static const _currencies = <String, (String, String)>{
    'USD': ('US Dollar', '\$'),
    'GBP': ('British Pound', '£'),
    'EUR': ('Euro', '€'),
    'BDT': ('Bangladeshi Taka', '৳'),
    'INR': ('Indian Rupee', '₹'),
    'AED': ('UAE Dirham', 'د.إ'),
  };

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _buildingCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _postCodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'United Kingdom');
  final _phoneCtrl = TextEditingController();
  final _customerIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  late String _currency = _currencies.containsKey(widget.suggestedCurrency)
      ? widget.suggestedCurrency
      : 'USD';
  String _paymentMethod = 'Cash';
  bool _isPaid = true;
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    final amount = widget.suggestedAmount;
    if (amount != null && amount > 0) {
      _amountCtrl.text = amount % 1 == 0
          ? amount.toStringAsFixed(0)
          : amount.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _emailCtrl,
      _buildingCtrl,
      _streetCtrl,
      _postCodeCtrl,
      _countryCtrl,
      _phoneCtrl,
      _customerIdCtrl,
      _amountCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;

  /// Picking a saved customer fills the form; the fields stay editable so a
  /// new customer can still be typed in.
  Future<void> _pickExistingCustomer() async {
    final picked = await showSearchablePicker<Customer>(
      context: context,
      title: 'Select customer',
      searchHint: 'Search name, phone or email',
      emptyMessage: 'No saved customers match',
      options: [
        for (final customer in widget.existingCustomers)
          PickerOption(
            value: customer,
            title: customer.fullName.isEmpty ? 'Customer' : customer.fullName,
            subtitle: [
              customer.phone,
              customer.email,
            ].where((v) => v.trim().isNotEmpty).join(' • '),
          ),
      ],
    );
    if (picked == null || !mounted) return;

    setState(() {
      _selectedCustomer = picked;
      _nameCtrl.text = picked.fullName;
      _emailCtrl.text = picked.email;
      _phoneCtrl.text = picked.phone;
      if (picked.address.trim().isNotEmpty) {
        _streetCtrl.text = picked.address.trim();
      }
    });
  }

  void _clearSelectedCustomer() {
    setState(() {
      _selectedCustomer = null;
      for (final c in [
        _nameCtrl,
        _emailCtrl,
        _phoneCtrl,
        _customerIdCtrl,
        _buildingCtrl,
        _streetCtrl,
        _postCodeCtrl,
      ]) {
        c.clear();
      }
    });
  }

  Future<void> _pickCountry() async {
    final picked = await showSearchablePicker<String>(
      context: context,
      title: 'Country',
      searchHint: 'Search country',
      emptyMessage: 'No country matches',
      options: [
        for (final country in kCountries)
          PickerOption(value: country, title: country),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _countryCtrl.text = picked);
  }

  bool get _canGenerate =>
      _nameCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _amount > 0;

  void _submit() {
    if (!_canGenerate) return;
    Navigator.pop(
      context,
      SmartInvoiceCustomer(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        buildingNumber: _buildingCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        postCode: _postCodeCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        customerId: _customerIdCtrl.text.trim(),
        existingCustomerId: _selectedCustomer?.id,
        currencyCode: _currency,
        currencySymbol: _currencies[_currency]!.$2,
        amount: _amount,
        paymentMethod: _paymentMethod,
        isPaid: _isPaid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _handle(),
            const SizedBox(height: 16),
            _header(),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('CUSTOMER INFORMATION'),
                    if (widget.existingCustomers.isNotEmpty) ...[
                      _customerSelector(),
                      const SizedBox(height: 12),
                    ],
                    _field(_nameCtrl, 'Full Name *', Icons.person_outline),
                    const SizedBox(height: 10),
                    _field(
                      _emailCtrl,
                      'Email Address *',
                      Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _smallLabel('Address'),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_buildingCtrl, 'Building number', null),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _field(_streetCtrl, 'Street', null)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(_postCodeCtrl, 'Post code', null),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _countryField()),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _field(
                      _phoneCtrl,
                      'Phone Number *',
                      Icons.call_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      _customerIdCtrl,
                      'Customer ID (Optional)',
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('PRICE DETAILS'),
                    _smallLabel('Currency'),
                    _currencyDropdown(),
                    const SizedBox(height: 10),
                    _field(
                      _amountCtrl,
                      'Amount',
                      null,
                      prefixText: '${_currencies[_currency]!.$2} ',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('PAYMENT METHOD'),
                    Row(
                      children: [
                        _choice(
                          label: 'Cash',
                          icon: Icons.payments_outlined,
                          selected: _paymentMethod == 'Cash',
                          onTap: () => setState(() => _paymentMethod = 'Cash'),
                        ),
                        const SizedBox(width: 10),
                        _choice(
                          label: 'Bank',
                          icon: Icons.account_balance_outlined,
                          selected: _paymentMethod == 'Bank',
                          onTap: () => setState(() => _paymentMethod = 'Bank'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel('PAYMENT STATUS'),
                    Row(
                      children: [
                        _choice(
                          label: 'Paid',
                          selected: _isPaid,
                          onTap: () => setState(() => _isPaid = true),
                        ),
                        const SizedBox(width: 10),
                        _choice(
                          label: 'Unpaid',
                          selected: !_isPaid,
                          onTap: () => setState(() => _isPaid = false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _actions(),
          ],
        ),
      ),
    );
  }

  Widget _customerSelector() {
    final selected = _selectedCustomer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickExistingCustomer,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected == null
                ? AppColors.fieldBackground
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected == null
                  ? AppColors.fieldBorder
                  : AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people_alt_outlined,
                size: 19,
                color: selected == null
                    ? AppColors.textSecondary
                    : AppColors.primary,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected == null
                          ? 'Select existing customer'
                          : selected.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected == null
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected == null
                          ? '${widget.existingCustomers.length} saved - or type a new one below'
                          : 'Tap to change - fields stay editable',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected != null)
                GestureDetector(
                  onTap: _clearSelectedCustomer,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countryField() {
    return GestureDetector(
      onTap: _pickCountry,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _countryCtrl.text.trim().isEmpty
                    ? 'Country'
                    : _countryCtrl.text.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _countryCtrl.text.trim().isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Center(
    child: Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.fieldBorder,
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.attach_money_rounded,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Invoice',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fill customer & payment details',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close_rounded, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
      ),
    ),
  );

  Widget _smallLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String hint,
    IconData? icon, {
    TextInputType? keyboardType,
    String? prefixText,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) => setState(() {}),
      cursorColor: AppColors.primary,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: AppColors.textSecondary, size: 19),
        filled: true,
        fillColor: AppColors.fieldBackground,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: _border(AppColors.fieldBorder),
        enabledBorder: _border(AppColors.fieldBorder),
        focusedBorder: _border(AppColors.primary),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color),
  );

  Widget _currencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _currency,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: [
            for (final entry in _currencies.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text('${entry.key} - ${entry.value.$1}'),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _currency = value);
          },
        ),
      ),
    );
  }

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _canGenerate ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.35,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: AppColors.surfaceForeground,
              ),
              label: Text(
                'Generate Invoice',
                style: TextStyle(
                  color: AppColors.surfaceForeground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
