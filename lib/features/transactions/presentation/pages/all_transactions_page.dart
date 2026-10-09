import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/network/api_service/commerce_events.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../invoice/data/repositories/invoice_repository_impl.dart';
import '../../../invoice/domain/entities/invoice.dart';
import '../../../invoice/domain/repositories/invoice_repository.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';
import '../utils/invoice_transaction.dart';
import '../widgets/transaction_tile.dart';
import 'reports_page.dart';

class AllTransactionsPage extends StatefulWidget {
  const AllTransactionsPage({super.key, this.repository});
  final InvoiceRepository? repository;
  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  late final InvoiceRepository _repository =
      widget.repository ?? InvoiceRepositoryImpl(ApiClient(baseUrl));
  final _search = TextEditingController();
  List<Invoice> _invoices = [];
  String _filter = 'All', _error = '';
  bool _loading = false;
  int _limit = 50;
  @override
  void initState() {
    super.initState();
    _load();
    CommerceEvents.revision.addListener(_load);
  }

  @override
  void dispose() {
    CommerceEvents.revision.removeListener(_load);
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final profile = Get.find<ProfileController>();
      if (profile.userId.isEmpty) await profile.fetchProfile();
      final invoices = await _repository.getInvoices(profile.userId);
      invoices.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
      if (mounted) setState(() => _invoices = invoices);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load transactions. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (mounted && code != null) {
      setState(() {
        _search.text = code;
        _limit = 50;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matches = _invoices.where((invoice) {
      final method = (invoice.paymentMethod ?? '').toLowerCase();
      final category = switch (_filter) {
        'Cash' => method.isEmpty || method.contains('cash'),
        'Card' => method.contains('card'),
        'Banked' => method.contains('bank') || method.contains('transfer'),
        'Expenses' => invoice.isPurchase,
        _ => true,
      };
      return category &&
          '${invoice.reference} ${invoice.customerName} ${invoice.customerEmail ?? ''} ${invoice.customerPhone ?? ''} ${invoice.deviceSearchText}'
              .toLowerCase()
              .contains(query);
    }).toList();
    final visible = matches.take(_limit).toList();
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(
            title: 'All Transactions',
            trailing: IconButton(
              tooltip: 'Reports',
              icon: const Icon(Icons.assessment_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsPage()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() => _limit = 50),
              decoration: InputDecoration(
                hintText: 'Search invoice, customer, device or IMEI',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Scan IMEI',
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scan,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: Text('${matches.length} transactions')),
                DropdownButton<String>(
                  value: _filter,
                  items: ['All', 'Cash', 'Card', 'Banked', 'Expenses']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _filter = value ?? 'All';
                    _limit = 50;
                  }),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error.isNotEmpty)
            ListTile(
              title: Text(_error),
              trailing: TextButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: visible.length + 1,
                itemBuilder: (context, index) {
                  if (index < visible.length) {
                    return TransactionTile(
                      entry: transactionFromInvoice(visible[index]),
                    );
                  }
                  if (visible.length < matches.length) {
                    return OutlinedButton(
                      onPressed: () => setState(() => _limit += 50),
                      child: const Text('Load older transactions'),
                    );
                  }
                  if (visible.isEmpty && !_loading && _error.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No matching transactions',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
