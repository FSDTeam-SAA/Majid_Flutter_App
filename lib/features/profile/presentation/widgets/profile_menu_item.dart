import 'package:flutter/material.dart';

import '../../../../core/utils/colors.dart';

class ProfileMenuItem extends StatelessWidget {
  final String label;

  /// Optional current selection, shown muted before the chevron.
  final String? value;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;

  /// Category icon shown at the head of the row. One semantic 24pt outline
  /// icon per row, aligned across the whole list, per the developer notes.
  final IconData? leadingIcon;

  /// Tints the leading icon and label, used for destructive rows such as
  /// Delete Account.
  final Color? accentColor;

  /// Tints the trailing [value] only, so a permission row can show its state
  /// in green or red without recolouring the label.
  final Color? valueColor;

  const ProfileMenuItem({
    super.key,
    required this.label,
    this.value,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.leadingIcon,
    this.accentColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Color(0x8012161D),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // 52 keeps the row above the 44pt minimum touch target the
          // accessibility note calls for.
          constraints: const BoxConstraints(minHeight: 52),
          padding: EdgeInsets.symmetric(
            horizontal: leadingIcon == null ? 24 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor ?? Color(0xFF232A36)),
          ),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                SizedBox(
                  width: 24,
                  child: Icon(
                    leadingIcon,
                    size: 20,
                    color: accentColor ?? AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: accentColor ?? textColor ?? AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
              if (value != null && value!.isNotEmpty) ...[
                Text(
                  value!,
                  style: TextStyle(
                    color: valueColor ?? iconColor ?? AppColors.textSecondary,
                    fontSize: 13.5,
                    fontWeight: valueColor == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right,
                color: iconColor ?? AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
