import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../controller/scan_data.dart';

class CarrierDropdown extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final List<ScanDropdownOption>? options;
  final ScanDropdownOption? selected;
  final ValueChanged<ScanDropdownOption>? onSelect;

  const CarrierDropdown({
    super.key,
    required this.isOpen,
    required this.onToggle,
    this.options,
    this.selected,
    this.onSelect,
  });

  @override
  State<CarrierDropdown> createState() => _CarrierDropdownState();
}

class _CarrierDropdownState extends State<CarrierDropdown> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void didUpdateWidget(covariant CarrierDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isOpen && oldWidget.isOpen) {
      _searchController.clear();
      _query = '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ScanDropdownOption> get _allOptions =>
      widget.options ?? verificationOptions;

  List<ScanDropdownOption> get _filteredOptions {
    if (_query.isEmpty) return _allOptions;
    return _allOptions
        .where((opt) => opt.label.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final allOptions = _allOptions;
    final filtered = _filteredOptions;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          // ── header (always visible, tappable) ──
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggle,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.selected?.label ?? 'iPhone Carrier Check',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      widget.isOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Text(
                      '${allOptions.length} verification types available',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── expanded panel ──
          if (widget.isOpen) ...[
            Divider(color: AppColors.fieldBorder, height: 20),

            // search bar
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.fieldBackground,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          child: Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(height: 8),

            // options list
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250),
              child: filtered.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'No services found',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _buildOption(filtered[i]),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(ScanDropdownOption opt) {
    final isSelected = widget.selected?.label == opt.label;
    final isFree = opt.type == 'Free';

    return GestureDetector(
      onTap: () => widget.onSelect?.call(opt),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: isSelected
            ? BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Text(
                opt.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isFree
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                opt.type,
                style: TextStyle(
                  color: isFree ? AppColors.primary : Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
