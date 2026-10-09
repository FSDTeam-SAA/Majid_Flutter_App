import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/colors.dart';
import '../controller/staff_session_controller.dart';

Future<void> showSwitchStaffSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      builder: (_) => const _SwitchStaffSheet(),
    );

class _SwitchStaffSheet extends StatefulWidget {
  const _SwitchStaffSheet();

  @override
  State<_SwitchStaffSheet> createState() => _SwitchStaffSheetState();
}

class _SwitchStaffSheetState extends State<_SwitchStaffSheet> {
  final _session = StaffSessionController.instance;
  final _pin = TextEditingController();
  final _password = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  Map<String, dynamic>? _selected;
  String? _error;
  bool _loading = true;
  bool _saving = false;
  bool _owner = false;
  bool _settingPin = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pin.dispose();
    _password.dispose();
    super.dispose();
  }

  String _message(Object error) {
    if (error is DioException && error.response?.data is Map) {
      return error.response!.data['message']?.toString() ?? 'Please retry.';
    }
    if (error is FormatException) return error.message;
    return 'Could not complete staff switching. Please retry.';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await _session.members();
      if (mounted) setState(() => _members = members);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_saving || (!_owner && _selected == null)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_owner) {
        await _session.returnToOwner(_password.text);
      } else if (_settingPin) {
        await _session.setPin(
          _selected!['id'] as String,
          _pin.text,
          _password.text,
        );
        _pin.clear();
        _password.clear();
        if (mounted) {
          setState(() {
            _selected = null;
            _settingPin = false;
          });
          await _load();
        }
        return;
      } else {
        await _session.switchStaff(_selected!['id'] as String, _pin.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _select(
    Map<String, dynamic>? member, {
    bool owner = false,
    bool setPin = false,
  }) {
    if (_saving) return;
    _pin.clear();
    _password.clear();
    setState(() {
      _selected = member;
      _owner = owner;
      _settingPin = setPin;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .75,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Switch Staff',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                _session.staffName.value.isEmpty
                    ? 'Owner account is active'
                    : 'Serving as ${_session.staffName.value}',
              ),
              const SizedBox(height: 12),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (!_loading && _members.isEmpty && _error == null)
                const Text('No staff members have been added to this shop.'),
              ..._members.map(
                (member) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  selected: _selected?['id'] == member['id'],
                  title: Text(member['name'] as String),
                  subtitle: member['hasPin'] == true
                      ? null
                      : const Text('Ask the owner to set a PIN'),
                  onTap: _saving || member['hasPin'] != true
                      ? null
                      : () => _select(member),
                  trailing: _session.staffId.value.isNotEmpty
                      ? null
                      : TextButton(
                          onPressed: _saving
                              ? null
                              : () => _select(member, setPin: true),
                          child: const Text('Set PIN'),
                        ),
                ),
              ),
              if (_session.staffId.value.isNotEmpty)
                TextButton(
                  onPressed: _saving ? null : () => _select(null, owner: true),
                  child: const Text('Switch to Owner'),
                ),
              if (_selected != null || _owner) ...[
                const SizedBox(height: 12),
                Text(
                  _owner
                      ? 'Enter the owner password'
                      : '${_settingPin ? 'Set PIN for' : 'Enter PIN for'} ${_selected!['name']}',
                ),
                const SizedBox(height: 8),
                if (!_owner)
                  TextField(
                    controller: _pin,
                    enabled: !_saving,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: '4-digit PIN'),
                    onSubmitted: _settingPin ? null : (_) => _submit(),
                  ),
                if (_owner || _settingPin)
                  TextField(
                    controller: _password,
                    enabled: !_saving,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Owner password',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(
                    _saving
                        ? 'Please wait...'
                        : _settingPin
                        ? 'Save PIN'
                        : 'Continue',
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.dangerColor),
                  ),
                ),
              if (!_loading && _error != null && _members.isEmpty)
                TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    ),
  );
}
