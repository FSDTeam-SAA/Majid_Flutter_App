import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_theme_controller.dart';
import '../controller/profile_controller.dart';

/// Opens the currency picker and saves the choice to the profile.
/// "No symbol" hides the currency marker across the app.
Future<void> showCurrencyPicker(
  BuildContext context,
  ProfileThemePalette palette,
) async {
  final ctrl = Get.find<ProfileController>();
  final current = ctrl.currencyCode.toUpperCase();

  final picked = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: palette.cardBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _CurrencySheet(palette: palette, current: current),
  );
  if (picked == null || picked == current) return;

  final profile = ctrl.profile.value;
  if (profile == null) return;

  await ctrl.updateProfile(
    firstName: profile.firstName,
    lastName: profile.lastName,
    phone: profile.phone,
    whatsappNumber: profile.whatsappNumber,
    shopName: profile.shopName,
    shopAddress: profile.shopAddress,
    currencyCode: picked,
  );
}

class _CurrencySheet extends StatelessWidget {
  final ProfileThemePalette palette;
  final String current;

  const _CurrencySheet({required this.palette, required this.current});

  @override
  Widget build(BuildContext context) {
    final entries = ProfileController.currencyOptions.entries.toList();

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.surfaceBorderColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Currency symbol',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Shown next to every amount in the app.',
                style: TextStyle(color: palette.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isSelected = entry.key == current;
                    final name =
                        ProfileController.currencyNames[entry.key] ?? entry.key;

                    return _CurrencyRow(
                      palette: palette,
                      code: entry.key,
                      symbol: entry.value,
                      name: name,
                      isSelected: isSelected,
                      onTap: () => Navigator.pop(context, entry.key),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  final ProfileThemePalette palette;
  final String code;
  final String symbol;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _CurrencyRow({
    required this.palette,
    required this.code,
    required this.symbol,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? palette.primaryColor.withValues(alpha: 0.12)
                : palette.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? palette.primaryColor.withValues(alpha: 0.45)
                  : palette.surfaceBorderColor,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  symbol.isEmpty ? '–' : symbol,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textPrimary,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (code != 'NONE')
                Text(
                  code,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(width: 10),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? palette.primaryColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? palette.primaryColor
                        : palette.surfaceBorderColor,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: palette.onPrimaryColor,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
