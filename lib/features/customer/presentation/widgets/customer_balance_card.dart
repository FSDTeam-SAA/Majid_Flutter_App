import 'package:flutter/material.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/network/api_service/commerce_events.dart';
import '../../data/repositories/customer_balance_repository.dart';
import '../../domain/entities/outstanding_invoice.dart';

class CustomerBalanceCard extends StatefulWidget {
  const CustomerBalanceCard({
    super.key,
    required this.customerId,
    required this.currencySymbol,
  });
  final String customerId;
  final String currencySymbol;
  @override
  State<CustomerBalanceCard> createState() => _CustomerBalanceCardState();
}

class _CustomerBalanceCardState extends State<CustomerBalanceCard> {
  late Future<List<OutstandingInvoice>> _balance = _load();
  Future<List<OutstandingInvoice>> _load() =>
      loadCustomerBalances(ApiClient(baseUrl), widget.customerId);
  @override
  void initState() {
    super.initState();
    CommerceEvents.revision.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() => _balance = _load());
  }

  @override
  void dispose() {
    CommerceEvents.revision.removeListener(_refresh);
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomerBalanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId) _balance = _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<OutstandingInvoice>>(
    future: _balance,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return ListTile(
          leading: const Icon(Icons.account_balance_wallet_outlined),
          title: const Text('Previous invoices balance'),
          subtitle: Text(
            snapshot.hasError
                ? 'Could not load balance'
                : 'Checking previous invoices...',
          ),
          trailing: snapshot.hasError
              ? IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)
              : null,
        );
      }
      final invoices = snapshot.data!;
      final currencies = invoices
          .map((invoice) => invoice.currency)
          .where((currency) => currency.isNotEmpty)
          .toSet();
      final total = invoices.fold<double>(
        0,
        (sum, invoice) => sum + invoice.due,
      );
      return ExpansionTile(
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: const Text('Previous invoices balance'),
        subtitle: Text(
          currencies.length > 1
              ? 'Outstanding invoices in multiple currencies'
              : '${currencies.isEmpty ? widget.currencySymbol : currencies.single} ${total.toStringAsFixed(2)} outstanding',
        ),
        children: [
          if (invoices.isEmpty)
            const ListTile(title: Text('No outstanding invoices')),
          for (final invoice in invoices)
            ListTile(
              title: Text(invoice.reference),
              subtitle: Text(invoice.date.split('T').first),
              trailing: Text(
                '${invoice.currency.isEmpty ? widget.currencySymbol : invoice.currency} ${invoice.due.toStringAsFixed(2)}',
              ),
            ),
        ],
      );
    },
  );
}
