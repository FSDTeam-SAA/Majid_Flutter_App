import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/colors.dart';

/// What the shopkeeper picked in the "Waiting for Parts" sheet.
class WaitingForPartsResult {
  final String partName;
  final String source;
  final int days;
  final String waitLabel;

  /// Single line the backend stores in `waitingForPartsDescription`, since it
  /// has no separate fields for the part or its source.
  final String description;

  /// Ready-to-send customer message.
  final String message;

  const WaitingForPartsResult({
    required this.partName,
    required this.source,
    required this.days,
    required this.waitLabel,
    required this.description,
    required this.message,
  });
}

Future<WaitingForPartsResult?> showWaitingForPartsSheet({
  required BuildContext context,
  required String customerName,
  required List<String> partSuggestions,
}) {
  return showModalBottomSheet<WaitingForPartsResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _WaitingForPartsSheet(
      customerName: customerName,
      partSuggestions: partSuggestions,
    ),
  );
}

class _WaitingForPartsSheet extends StatefulWidget {
  final String customerName;
  final List<String> partSuggestions;

  const _WaitingForPartsSheet({
    required this.customerName,
    required this.partSuggestions,
  });

  @override
  State<_WaitingForPartsSheet> createState() => _WaitingForPartsSheetState();
}

class _WaitingForPartsSheetState extends State<_WaitingForPartsSheet> {
  static const _sources = ['Online order', 'Local supplier'];
  static const _waitOptions = [
    ('Same day', 1),
    ('1 day', 1),
    ('2 days', 2),
    ('Custom', 0),
  ];

  final TextEditingController _customDaysCtrl = TextEditingController();

  String _partName = '';
  String _source = _sources.first;
  String _waitLabel = '2 days';

  @override
  void dispose() {
    _customDaysCtrl.dispose();
    super.dispose();
  }

  bool get _isCustomWait => _waitLabel == 'Custom';

  int get _days {
    if (_isCustomWait) {
      final typed = int.tryParse(_customDaysCtrl.text.trim()) ?? 0;
      return typed > 0 ? typed : 1;
    }
    return _waitOptions.firstWhere((option) => option.$1 == _waitLabel).$2;
  }

  String get _waitText {
    if (!_isCustomWait) return _waitLabel;
    final days = _days;
    return days == 1 ? '1 day' : '$days days';
  }

  String get _firstName {
    final parts = widget.customerName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  String get _description =>
      '$_partName — ${_source.toLowerCase()}, expected ${_waitText.toLowerCase()}';

  String get _message {
    final part = _partName.isEmpty ? 'part' : _partName.toLowerCase();
    final sourceText = _source == 'Online order'
        ? 'It has been ordered online'
        : 'It has been ordered from our local supplier';
    final waitText = _waitLabel == 'Same day'
        ? 'and is expected later today'
        : 'and is expected within ${_waitText.toLowerCase()}';

    return 'Hi $_firstName, we\'re waiting for the $part required for your '
        'repair. $sourceText $waitText. We\'ll update you as soon as it '
        'arrives.\nThank you for your patience.';
  }

  bool get _canConfirm => _partName.trim().isNotEmpty;

  Future<void> _pickPart() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          _PartPicker(suggestions: widget.partSuggestions, initial: _partName),
    );
    if (picked == null || !mounted) return;
    setState(() => _partName = picked);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fieldBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Waiting for Parts',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            _CustomerRow(name: widget.customerName),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Part required'),
                    _TapField(
                      value: _partName.isEmpty
                          ? 'Choose or search a part'
                          : _partName,
                      isPlaceholder: _partName.isEmpty,
                      onTap: _pickPart,
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Part source'),
                    _OptionField(
                      value: _source,
                      options: _sources,
                      onChanged: (value) => setState(() => _source = value),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Estimated wait'),
                    _OptionField(
                      value: _waitLabel,
                      options: _waitOptions.map((o) => o.$1).toList(),
                      onChanged: (value) => setState(() => _waitLabel = value),
                    ),
                    if (_isCustomWait) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _customDaysCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: 'How many days?',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.fieldBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.fieldBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AppColors.fieldBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _MessagePreview(message: _message),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ActionBar(
              canConfirm: _canConfirm,
              onCancel: () => Navigator.pop(context),
              onConfirm: () => Navigator.pop(
                context,
                WaitingForPartsResult(
                  partName: _partName.trim(),
                  source: _source,
                  days: _days,
                  waitLabel: _waitText,
                  description: _description,
                  message: _message,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sticky footer holding the sheet's two actions.
class _ActionBar extends StatelessWidget {
  final bool canConfirm;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ActionBar({
    required this.canConfirm,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 1, color: AppColors.fieldBorder),
        const SizedBox(height: 14),
        if (!canConfirm) ...[
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Choose a part to continue',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
        ],
        Row(
          children: [
            Expanded(
              child: _SheetButton(
                label: 'Cancel',
                onTap: onCancel,
                background: AppColors.fieldBackground,
                foreground: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _SheetButton(
                label: 'Confirm & Notify',
                icon: Icons.send_rounded,
                onTap: canConfirm ? onConfirm : null,
                // Stays the brand green either way; the disabled state just
                // fades it rather than turning grey.
                background: canConfirm
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.35),
                foreground: canConfirm
                    ? AppColors.surfaceForeground
                    : AppColors.surfaceForeground.withValues(alpha: 0.55),
                glow: canConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color background;
  final Color foreground;
  final bool glow;

  const _SheetButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
    this.icon,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(16),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: foreground),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerRow extends StatelessWidget {
  final String name;

  const _CustomerRow({required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Icon(
            Icons.person_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              name.isEmpty ? 'Customer' : name,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  final String value;
  final bool isPlaceholder;
  final VoidCallback onTap;

  const _TapField({
    required this.value,
    required this.isPlaceholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
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
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: isPlaceholder
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionField extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _OptionField({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textPrimary,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _MessagePreview extends StatelessWidget {
  final String message;

  const _MessagePreview({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Text(
                'Message preview',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable list of known parts, with a free-text fallback.
class _PartPicker extends StatefulWidget {
  final List<String> suggestions;
  final String initial;

  const _PartPicker({required this.suggestions, required this.initial});

  @override
  State<_PartPicker> createState() => _PartPickerState();
}

class _PartPickerState extends State<_PartPicker> {
  late final TextEditingController _searchCtrl = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _query => _searchCtrl.text.trim();

  List<String> get _matches {
    final query = _query.toLowerCase();
    if (query.isEmpty) return widget.suggestions;
    return widget.suggestions
        .where((part) => part.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final matches = _matches;
    final canUseTyped =
        _query.isNotEmpty &&
        !widget.suggestions.any(
          (part) => part.toLowerCase() == _query.toLowerCase(),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Part required',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose an existing part or type to search.',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. iPhone 15 Pro replacement screen',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
                fontSize: 13.5,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.fieldBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.fieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (canUseTyped)
            _PartOption(
              label: 'Use "$_query"',
              isCustom: true,
              onTap: () => Navigator.pop(context, _query),
            ),
          Flexible(
            child: matches.isEmpty && !canUseTyped
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'No matching parts. Type a name to use it.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 4),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => _PartOption(
                      label: matches[index],
                      onTap: () => Navigator.pop(context, matches[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PartOption extends StatelessWidget {
  final String label;
  final bool isCustom;
  final VoidCallback onTap;

  const _PartOption({
    required this.label,
    required this.onTap,
    this.isCustom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isCustom
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCustom
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.fieldBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isCustom ? Icons.add_rounded : Icons.memory_rounded,
                size: 17,
                color: isCustom ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: isCustom ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
