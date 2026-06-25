import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../controller/stock_controller.dart';

void showAddCategorySheet(
  BuildContext context, {
  String? existingId,
  String? existingName,
  String? existingImageUrl,
}) {
  final controller = TextEditingController(text: existingName);
  String? pickedImagePath;
  final isEdit = existingId != null;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Category' : 'Add New Category',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.primary, width: 1.2),
                ),
                child: TextField(
                  controller: controller,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Enter category name',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(height: 14),
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (picked != null) {
                    setDialogState(() => pickedImagePath = picked.path);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: _buildImageContent(pickedImagePath, existingImageUrl),
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = controller.text.trim();
                        if (name.isEmpty) {
                          showErrorSnackbar('Please enter a category name');
                          return;
                        }

                        final stockCtrl = Get.find<StockController>();
                        bool success;

                        if (isEdit) {
                          success = await stockCtrl.updateCategory(
                            id: existingId,
                            name: name,
                            imagePath: pickedImagePath,
                          );
                        } else {
                          success = await stockCtrl.createCategory(
                            name: name,
                            imagePath: pickedImagePath,
                          );
                        }

                        if (!context.mounted) return;
                        if (success) {
                          Navigator.pop(context);
                          showSuccessSnackbar(
                            isEdit ? 'Category updated' : 'Category created',
                          );
                        } else {
                          showErrorSnackbar(stockCtrl.errorMessage.value);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: Text(
                        isEdit ? 'Save Changes' : 'Create Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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

Widget _buildImageContent(String? pickedPath, String? existingUrl) {
  if (pickedPath != null) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.file(File(pickedPath), fit: BoxFit.cover),
    );
  }

  if (existingUrl != null && existingUrl.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        existingUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _UploadPlaceholder(),
      ),
    );
  }

  return const _UploadPlaceholder();
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
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
          child: Icon(Icons.upload_rounded, color: AppColors.primary, size: 26),
        ),
        SizedBox(height: 12),
        Text(
          'Upload Category Image',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Upload a transparent PNG image for a cleaner and more professional appearance.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
