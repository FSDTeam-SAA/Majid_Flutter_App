import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../scan/presentation/pages/barcode_scanner_page.dart';
import '../controller/repair_data.dart';
import '../utils/repair_request_formatter.dart';
import '../widgets/repair_card.dart';
import 'repair_request_details_page.dart';

class AllRepairRequestsPage extends StatefulWidget {
  const AllRepairRequestsPage({
    super.key,
    this.initialQuery = '',
    this.apiClient,
  });
  final String initialQuery;
  final ApiClient? apiClient;
  @override
  State<AllRepairRequestsPage> createState() => _AllRepairRequestsPageState();
}

class _AllRepairRequestsPageState extends State<AllRepairRequestsPage> {
  late final ApiClient _api = widget.apiClient ?? ApiClient(baseUrl);
  late final TextEditingController _search = TextEditingController(
    text: widget.initialQuery,
  );
  List<RepairItem> _repairs = [], _searchRepairs = [];
  bool _loading = false, _searching = false, _searchComplete = false;
  int _page = 0, _pages = 1, _total = 0, _searchGeneration = 0;
  String _error = '';
  Timer? _debounce;
  String get _query => _search.text.trim().toLowerCase();
  @override
  void initState() {
    super.initState();
    _load(refresh: true);
    if (_query.isNotEmpty) _searchChanged();
  }

  @override
  void dispose() {
    _searchGeneration++;
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = '';
      if (refresh) {
        _searchComplete = false;
        _searchRepairs = [];
      }
    });
    try {
      final page = refresh ? 1 : _page + 1;
      final response = await _api.get(
        RepairRequestEndpoints.myHistory,
        query: {'page': page, 'limit': 20},
      );
      final data = response.data['data'];
      if (data is! List) throw const FormatException('Invalid repair response');
      if (!mounted) return;
      final meta = response.data['meta'];
      setState(() {
        _page = page;
        _pages = meta is Map ? (meta['totalPage'] as num?)?.toInt() ?? 1 : 1;
        _total = meta is Map
            ? (meta['total'] as num?)?.toInt() ?? data.length
            : data.length;
        final parsed = data
            .whereType<Map>()
            .map((item) => repairItemFromJson(Map<String, dynamic>.from(item)))
            .toList();
        _repairs = refresh ? parsed : [..._repairs, ...parsed];
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load repair history. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _searchChanged() {
    _debounce?.cancel();
    _searchGeneration++;
    setState(() {
      _searching = false;
      _error = '';
    });
    if (_query.isNotEmpty && !_searchComplete) {
      _debounce = Timer(const Duration(milliseconds: 300), _loadSearch);
    }
  }

  Future<void> _loadSearch() async {
    final generation = ++_searchGeneration;
    setState(() {
      _searching = true;
      _error = '';
    });
    final found = <RepairItem>[];
    try {
      var pages = 1;
      for (var page = 1; page <= pages; page++) {
        final response = await _api.get(
          RepairRequestEndpoints.myHistory,
          query: {'page': page, 'limit': 100},
        );
        if (!mounted || generation != _searchGeneration) return;
        final data = response.data['data'];
        if (data is! List) {
          throw const FormatException('Invalid repair response');
        }
        final meta = response.data['meta'];
        pages = meta is Map ? (meta['totalPage'] as num?)?.toInt() ?? 1 : 1;
        found.addAll(
          data.whereType<Map>().map(
            (item) => repairItemFromJson(Map<String, dynamic>.from(item)),
          ),
        );
        setState(() => _searchRepairs = List.of(found));
      }
      if (mounted && generation == _searchGeneration) {
        setState(() => _searchComplete = true);
      }
    } catch (_) {
      if (mounted && generation == _searchGeneration) {
        setState(
          () => _error = 'Could not search all older repairs. Please retry.',
        );
      }
    } finally {
      if (mounted && generation == _searchGeneration) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (!mounted || code == null) return;
    final uri = Uri.tryParse(code);
    _search.text = uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : code;
    _searchChanged();
  }

  Future<void> _open(RepairItem item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => RepairRequestDetailsPage(repair: item.raw),
      ),
    );
    if (!mounted) return;
    await _load(refresh: true);
    if (mounted && _query.isNotEmpty) _searchChanged();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _query.isEmpty
        ? _repairs
        : [
            ..._repairs,
            ..._searchRepairs,
          ].where((item) => repairMatchesQuery(item, _query)).toList();
    final seen = <String>{};
    final unique = rows
        .where((item) => seen.add('${item.raw['_id']}'))
        .toList();
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Repair Requests'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _search,
              onChanged: (_) => _searchChanged(),
              decoration: InputDecoration(
                hintText: 'Search customer, device or IMEI',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          _searchChanged();
                        },
                      ),
                    IconButton(
                      tooltip: 'Scan IMEI or repair QR',
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scan,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_searching || _loading) const LinearProgressIndicator(),
          if (_error.isNotEmpty)
            ListTile(
              title: Text(_error),
              trailing: TextButton(
                onPressed: _query.isEmpty
                    ? () => _load(refresh: _page == 0)
                    : _loadSearch,
                child: const Text('Retry'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              _query.isEmpty
                  ? '$_total records'
                  : '${unique.length} matches${_searching ? ' · searching older repairs...' : ''}',
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ++_searchGeneration;
                await _load(refresh: true);
                if (mounted && _query.isNotEmpty) await _loadSearch();
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                itemCount: unique.length + 1,
                itemBuilder: (context, index) {
                  if (index < unique.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RepairCard(
                        item: unique[index],
                        onViewReport: () => _open(unique[index]),
                      ),
                    );
                  }
                  if (_query.isEmpty && _page < _pages) {
                    return OutlinedButton(
                      onPressed: _loading ? null : () => _load(),
                      child: const Text('Load older repairs'),
                    );
                  }
                  if (unique.isEmpty &&
                      !_loading &&
                      !_searching &&
                      _error.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No matching repair requests',
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
