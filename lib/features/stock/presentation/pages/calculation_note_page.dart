import 'package:flutter/material.dart';

import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../domain/entities/calculation_line.dart';
import '../theme/checkout_tokens.dart';

/// What comes back when the shopkeeper saves the note.
class CalculationNoteResult {
  final List<CalculationLine> lines;
  final String note;

  const CalculationNoteResult({required this.lines, required this.note});
}

/// Lets the shopkeeper put a name against each hand-keyed line so the review
/// screen and receipt read as items rather than bare sums.
class CalculationNotePage extends StatefulWidget {
  final List<CalculationLine> lines;
  final String initialNote;

  const CalculationNotePage({
    super.key,
    required this.lines,
    this.initialNote = '',
  });

  @override
  State<CalculationNotePage> createState() => _CalculationNotePageState();
}

class _CalculationNotePageState extends State<CalculationNotePage> {
  late final List<CalculationLine> _lines = [...widget.lines];
  late final List<TextEditingController> _nameControllers = [
    for (final line in _lines) TextEditingController(text: line.name),
  ];
  late final TextEditingController _noteCtrl = TextEditingController(
    text: widget.initialNote,
  );

  @override
  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    _noteCtrl.dispose();
    super.dispose();
  }

  void _addLine() {
    setState(() {
      _lines.add(
        const CalculationLine(expression: '0', quantity: 1, amount: 0),
      );
      _nameControllers.add(TextEditingController());
    });
  }

  void _save() {
    final named = <CalculationLine>[
      for (var i = 0; i < _lines.length; i++)
        _lines[i].copyWith(name: _nameControllers[i].text.trim()),
    ];
    Navigator.pop(
      context,
      CalculationNoteResult(lines: named, note: _noteCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Calculation Note'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
              children: [
                Text(
                  'Add item names for the calculated lines.',
                  style: CheckoutTokens.text(
                    size: 13,
                    weight: FontWeight.w500,
                    color: CheckoutTokens.softText,
                  ),
                ),
                const SizedBox(height: 16),
                _linesCard(),
                const SizedBox(height: 18),
                Text(
                  'Additional notes (optional)',
                  style: CheckoutTokens.text(
                    size: 13,
                    weight: FontWeight.w600,
                    color: CheckoutTokens.softText,
                  ),
                ),
                const SizedBox(height: 8),
                _noteField(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: _saveButton(),
          ),
        ],
      ),
    );
  }

  Widget _linesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CheckoutTokens.keySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CheckoutTokens.keyEdge),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 26),
              Expanded(child: Text('Item name', style: CheckoutTokens.label)),
              Text('Qty / Amount', style: CheckoutTokens.label),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _lines.length; i++) ...[
            _lineRow(i),
            const SizedBox(height: 10),
          ],
          _addButton(),
        ],
      ),
    );
  }

  Widget _lineRow(int index) {
    final line = _lines[index];

    return Row(
      children: [
        Icon(
          Icons.drag_indicator_rounded,
          size: 18,
          color: CheckoutTokens.softText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _nameControllers[index],
            style: CheckoutTokens.text(size: 14, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Item name',
              hintStyle: CheckoutTokens.text(
                size: 13.5,
                weight: FontWeight.w500,
                color: CheckoutTokens.softText,
              ),
              filled: true,
              fillColor: CheckoutTokens.surfaceMuted,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: _border(CheckoutTokens.keyEdge),
              enabledBorder: _border(CheckoutTokens.keyEdge),
              focusedBorder: _border(CheckoutTokens.limeInk),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 84,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: CheckoutTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                line.expression,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CheckoutTokens.text(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: CheckoutTokens.softText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '= ${_money(line.amount)}',
                maxLines: 1,
                style: CheckoutTokens.text(size: 13, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _addButton() {
    return GestureDetector(
      onTap: _addLine,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: CheckoutTokens.limeSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: CheckoutTokens.limeInk.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: CheckoutTokens.limeInk),
            const SizedBox(width: 7),
            Text(
              'Add item',
              style: CheckoutTokens.text(
                size: 14,
                weight: FontWeight.w700,
                color: CheckoutTokens.limeInk,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteField() {
    return TextField(
      controller: _noteCtrl,
      maxLines: 4,
      maxLength: 500,
      style: CheckoutTokens.text(size: 14, weight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: 'Type any additional notes here...',
        hintStyle: CheckoutTokens.text(
          size: 13.5,
          weight: FontWeight.w500,
          color: CheckoutTokens.softText,
        ),
        filled: true,
        fillColor: CheckoutTokens.keySurface,
        border: _border(CheckoutTokens.keyEdge),
        enabledBorder: _border(CheckoutTokens.keyEdge),
        focusedBorder: _border(CheckoutTokens.limeInk),
      ),
    );
  }

  Widget _saveButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _save,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: CheckoutTokens.limeGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              'Save',
              style: CheckoutTokens.text(
                size: 16,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color),
  );

  String _money(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}
