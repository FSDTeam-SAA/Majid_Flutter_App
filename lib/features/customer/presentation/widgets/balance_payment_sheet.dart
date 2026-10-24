import 'package:flutter/material.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../data/repositories/customer_balance_repository.dart';
import '../../domain/entities/outstanding_invoice.dart';

/// Returns the old invoices to settle; an empty list means today's bill only.
Future<List<OutstandingInvoice>?> chooseBalancePayment(
  BuildContext context, {
  required ApiClient api,
  required String customerId,
  required double today,
  required String currencyCode,
  required String currencySymbol,
}) => showModalBottomSheet<List<OutstandingInvoice>>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _BalancePaymentSheet(
    api: api,
    customerId: customerId,
    today: today,
    currencyCode: currencyCode,
    currencySymbol: currencySymbol,
  ),
);

class _BalancePaymentSheet extends StatefulWidget {
  const _BalancePaymentSheet({
    required this.api,
    required this.customerId,
    required this.today,
    required this.currencyCode,
    required this.currencySymbol,
  });
  final ApiClient api;
  final String customerId, currencyCode, currencySymbol;
  final double today;
  @override
  State<_BalancePaymentSheet> createState() => _BalancePaymentSheetState();
}

class _BalancePaymentSheetState extends State<_BalancePaymentSheet> {
  late Future<List<OutstandingInvoice>> _balances = _load();
  Future<List<OutstandingInvoice>> _load() =>
      loadCustomerBalances(widget.api, widget.customerId);
  String _money(double value) =>
      '${widget.currencySymbol}${value.toStringAsFixed(2)}';
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .8,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<OutstandingInvoice>>(
          future: _balances,
          builder: (context, snapshot) {
            final invoices = snapshot.data ?? const <OutstandingInvoice>[];
            final sameCurrency = invoices.every(
              (invoice) =>
                  invoice.currency.isEmpty ||
                  invoice.currency == widget.currencyCode.toUpperCase(),
            );
            final totalDue = invoices.fold<double>(
              0,
              (sum, invoice) => sum + invoice.due,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose what to pay',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('Today: ${_money(widget.today)}'),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (snapshot.hasError) ...[
                  const Text(
                    'Could not load previous invoices. You can pay today only or retry.',
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final balances = _load();
                      setState(() {
                        _balances = balances;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry balances'),
                  ),
                ],
                if (snapshot.hasData) ...[
                  ExpansionTile(
                    title: Text(
                      'Previous balance: ${sameCurrency ? _money(totalDue) : 'multiple currencies'}',
                    ),
                    children: [
                      if (invoices.isEmpty)
                        const ListTile(title: Text('No previous balance')),
                      for (final invoice in invoices)
                        ListTile(
                          title: Text(invoice.reference),
                          subtitle: Text(invoice.date.split('T').first),
                          trailing: Text(
                            '${invoice.currency.isEmpty ? widget.currencySymbol : invoice.currency} ${invoice.due.toStringAsFixed(2)}',
                          ),
                        ),
                    ],
                  ),
                  if (!sameCurrency)
                    const Text(
                      'Previous invoices use a different currency. Settle them separately.',
                    ),
                  if (invoices.isNotEmpty)
                    FilledButton(
                      onPressed: sameCurrency
                          ? () => Navigator.pop(context, invoices)
                          : null,
                      child: Text(
                        'Pay All · ${sameCurrency ? _money(widget.today + totalDue) : 'unavailable'}',
                      ),
                    ),
                ],
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, <OutstandingInvoice>[]),
                  child: Text('Pay Total Today Only · ${_money(widget.today)}'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
