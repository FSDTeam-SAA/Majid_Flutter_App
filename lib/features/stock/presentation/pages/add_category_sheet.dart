import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';

void showAddCategorySheet(BuildContext context, {String? existingName}) {
  final controller = TextEditingController(text: existingName);
  bool hasImage = existingName != null;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111A1E),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existingName != null ? 'Edit Category' : 'Add New Category',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              // Name field
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1520),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.primary, width: 1.2),
                ),
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Enter category name',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Image upload area
              GestureDetector(
                onTap: () => setDialogState(() => hasImage = !hasImage),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1520),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: hasImage
                      ? Center(
                          child: const Icon(Icons.smartphone, color: Color(0xFFD4A853), size: 110),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 1.5),
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              child: const Icon(Icons.upload_rounded, color: AppColors.primary, size: 26),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Upload Category Image',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Upload a transparent PNG image for a cleaner and more professional appearance.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        existingName != null ? 'Save Changes' : 'Create Category',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
