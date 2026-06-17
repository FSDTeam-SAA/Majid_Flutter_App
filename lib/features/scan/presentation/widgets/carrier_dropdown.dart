import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../controller/scan_data.dart';

class CarrierDropdown extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;

  const CarrierDropdown({super.key, required this.isOpen, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111A24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A2840)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                  child: const Text('FREE', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'iPhone Carrier Check',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 2),
                child: Text('8 verification types available', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ),
            if (isOpen) ...[
              const Divider(color: Color(0xFF1A2840), height: 20),
              ...verificationOptions.map(_buildOption),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOption(ScanDropdownOption opt) {
    final isFree = opt.type == 'Free';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(opt.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isFree ? AppColors.primary.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              opt.type,
              style: TextStyle(color: isFree ? AppColors.primary : Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
