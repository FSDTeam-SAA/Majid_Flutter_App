import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';

/// Asks for a product name that is not in the inventory yet.
///
/// Returns the trimmed name, or `null` when cancelled.
Future<String?> showNewItemNameDialog(
  BuildContext context, {
  String initialValue = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NewItemNameDialog(initialValue: initialValue),
  );
}

class _NewItemNameDialog extends StatefulWidget {
  final String initialValue;

  const _NewItemNameDialog({required this.initialValue});

  @override
  State<_NewItemNameDialog> createState() => _NewItemNameDialogState();
}

class _NewItemNameDialogState extends State<_NewItemNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'New item',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This item is not in your inventory. Give it a name to use on '
            'this invoice.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            cursorColor: AppColors.primary,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. iPhone 15 Pro charging cable',
              hintStyle: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
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
                borderSide: BorderSide(color: AppColors.primary, width: 1.3),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surfaceForeground,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Add item',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _canSubmit
                  ? AppColors.surfaceForeground
                  : AppColors.surfaceForeground.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
