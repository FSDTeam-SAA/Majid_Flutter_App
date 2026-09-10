import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/colors.dart';

/// Six-digit code entry used by every verification screen: sign-in two-factor,
/// new-device approval, account deletion and customer consent.
///
/// It is one real [TextField] behind six painted boxes rather than six
/// separate fields, so paste, autofill from an SMS and backspace all behave
/// the way people expect.
class CodeInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;

  /// Fires as soon as the last digit is entered.
  final ValueChanged<String>? onCompleted;
  final bool autofocus;

  /// Paints the boxes red after a rejected code.
  final bool hasError;
  final bool enabled;

  const CodeInputField({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    this.autofocus = true,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  State<CodeInputField> createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<CodeInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    widget.onChanged(value);
    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text;

    return Stack(
      children: [
        // The real field is transparent and sits behind the boxes; tapping
        // anywhere on the row focuses it.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _handleChanged,
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.length, (index) {
              final filled = index < value.length;
              final isNext = index == value.length && _focusNode.hasFocus;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == widget.length - 1 ? 0 : 8,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.hasError
                            ? AppColors.dangerColor
                            : isNext
                            ? AppColors.primary
                            : AppColors.fieldBorder,
                        width: isNext || widget.hasError ? 1.6 : 1,
                      ),
                    ),
                    child: Text(
                      filled ? value[index] : '',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
