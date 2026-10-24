import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';
import '../../domain/entities/scan_service_option.dart';
import '../../domain/repositories/imei_repository.dart';
import 'device_report_page.dart';

class BulkScanPage extends StatefulWidget {
  const BulkScanPage({
    super.key,
    required this.repository,
    required this.services,
    required this.onResults,
    this.selectedService,
    this.initialIdentifiers = const [],
  });

  final ImeiRepository repository;
  final List<ScanDropdownOption> services;
  final ScanDropdownOption? selectedService;
  final List<String> initialIdentifiers;
  final ValueChanged<List<Map<String, dynamic>>> onResults;

  @override
  State<BulkScanPage> createState() => _BulkScanPageState();
}

class _BulkScanPageState extends State<BulkScanPage> {
  late final TextEditingController _input;
  ScanDropdownOption? _service;
  bool _checking = false;
  String? _error;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _input = TextEditingController(text: widget.initialIdentifiers.join('\n'));
    _service = widget.selectedService ?? widget.services.firstOrNull;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_checking) return;
    // Preserve identifier boundaries: never join two pasted IMEIs together.
    final identifiers = _input.text
        .split(RegExp(r'[\s,;]+'))
        .where((value) => value.isNotEmpty)
        .map((value) => value.toUpperCase())
        .toSet()
        .toList();
    final invalid = identifiers.where(
      (value) => !RegExp(r'^[A-Z0-9]{4,}$').hasMatch(value),
    );
    final serviceId = _service?.serviceId;
    if (identifiers.isEmpty ||
        identifiers.length > 20 ||
        invalid.isNotEmpty ||
        serviceId == null) {
      setState(
        () => _error = identifiers.isEmpty
            ? 'Enter at least one IMEI or serial number.'
            : identifiers.length > 20
            ? 'Check up to 20 devices at a time.'
            : invalid.isNotEmpty
            ? 'Use letters and numbers only: ${invalid.first}'
            : 'Select a verification service.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _checking = true;
      _error = null;
      _results = [];
    });
    try {
      final results = await widget.repository.checkImeis(
        imeis: identifiers,
        serviceId: serviceId,
      );
      if (!mounted) return;
      setState(() => _results = results);
      widget.onResults(results);
    } on ImeiScanException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.message.isEmpty
              ? 'Bulk check failed. Check scan history before retrying.'
              : e.message,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not confirm the results. Check scan history before retrying.',
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  bool _hasReport(Map<String, dynamic> result) {
    final data = result['data'];
    return result['ok'] == true && data is Map && data.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final completed = _results.where(_hasReport).length;
    return PopScope(
      canPop: !_checking,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Bulk checking'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          automaticallyImplyLeading: !_checking,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Check up to 20 devices',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Paste IMEIs or serial numbers, separated by new lines, spaces or commas. Duplicates are checked once.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                key: const ValueKey('bulk-identifiers'),
                controller: _input,
                enabled: !_checking,
                minLines: 4,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
                autocorrect: false,
                enableSuggestions: false,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'IMEIs / serial numbers',
                  hintText: '351297474660682\n353806443927036',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ScanDropdownOption>(
                initialValue: _service,
                isExpanded: true,
                dropdownColor: AppColors.cardBackground,
                decoration: const InputDecoration(
                  labelText: 'Verification service',
                ),
                items: [
                  for (final service in widget.services)
                    DropdownMenuItem(
                      value: service,
                      child: Text(
                        '${service.label} · ${service.type}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                ],
                onChanged: _checking
                    ? null
                    : (value) => setState(() => _service = value),
              ),
              const SizedBox(height: 8),
              Text(
                'The selected service applies to every device. Paid services charge per device.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _checking ? null : _check,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: _checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.playlist_add_check_rounded),
                label: Text(
                  _checking
                      ? 'Checking devices…'
                      : _results.isEmpty
                      ? 'Check devices'
                      : 'Check again',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: TextStyle(color: AppColors.dangerColor)),
              ],
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  '$completed of ${_results.length} reports ready',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final result in _results)
                  Card(
                    color: AppColors.cardBackground,
                    child: ListTile(
                      title: Text(
                        result['imei']?.toString() ?? 'Device',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        _hasReport(result)
                            ? 'View device report'
                            : result['message']?.toString() ??
                                  'No device information found.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: Icon(
                        _hasReport(result)
                            ? Icons.chevron_right
                            : Icons.error_outline,
                        color: _hasReport(result)
                            ? AppColors.primary
                            : AppColors.dangerColor,
                      ),
                      onTap: !_hasReport(result)
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DeviceReportPage(report: result),
                              ),
                            ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
