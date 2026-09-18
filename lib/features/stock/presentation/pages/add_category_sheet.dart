import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/category.dart';
import '../controller/stock_controller.dart';
import '../theme/checkout_tokens.dart';

Future<Category?> showAddCategorySheet(
  BuildContext context, {
  String? existingId,
  String? existingName,
  String? existingImageUrl,
}) async {
  final controller = TextEditingController(text: existingName);
  String? pickedImagePath;
  var isSubmitting = false;
  final isEdit = existingId != null;

  return showDialog<Category?>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final stockCtrl = Get.find<StockController>();

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: CheckoutTokens.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
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
                  if (isSubmitting) return;
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
                      onPressed: isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.primary, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(dialogContext, null),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name label
                  Text(
                    'NAME *',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: TextField(
                      controller: controller,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.folder_open_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        hintText: 'e.g. Electronics, Phones, Tablets',
                        hintStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = controller.text.trim();
                              if (name.isEmpty) {
                                showErrorSnackbar(
                                  'Please enter a category name',
                                );
                                return;
                              }

                              final stockCtrl = Get.find<StockController>();
                              // The save can take several seconds (the API
                              // host cold-starts), so the button has to show
                              // it is working — otherwise the tap looks
                              // ignored and repeated taps fire duplicate
                              // create requests.
                              setDialogState(() => isSubmitting = true);

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
                              setDialogState(() => isSubmitting = false);

                              if (success) {
                                Navigator.pop(context);
                                showSuccessSnackbar(
                                  isEdit
                                      ? 'Category updated'
                                      : 'Category created',
                                );
                              } else {
                                final error = stockCtrl.errorMessage.value;
                                showErrorSnackbar(
                                  error.isEmpty
                                      ? 'Could not save the category'
                                      : error,
                                );
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
                      child: isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              isEdit ? 'Save Changes' : 'Create Category',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Obx(() {
                    final isSaving = stockCtrl.isSaving.value;

                    return Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(dialogContext, null),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: BorderSide(color: AppColors.fieldBorder, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final name = controller.text.trim();
                                    if (name.isEmpty) {
                                      showErrorSnackbar('Please enter a category name');
                                      return;
                                    }

                                    Category? resultCategory;

                                    if (isEdit) {
                                      final success = await stockCtrl.updateCategory(
                                        id: existingId,
                                        name: name,
                                        imagePath: pickedImagePath,
                                      );
                                      if (success) {
                                        resultCategory = Category(
                                          id: existingId,
                                          name: name,
                                          imageUrl: pickedImagePath ?? currentImageUrl,
                                        );
                                      }
                                    } else {
                                      resultCategory = await stockCtrl.createCategory(
                                        name: name,
                                        imagePath: pickedImagePath,
                                      );
                                    }

                                    if (!dialogContext.mounted) return;
                                    if (resultCategory != null || isEdit) {
                                      Navigator.pop(dialogContext, resultCategory);
                                      showSuccessSnackbar(
                                        isEdit
                                            ? 'Category updated successfully'
                                            : 'Category created successfully',
                                      );
                                    } else {
                                      showErrorSnackbar(
                                        stockCtrl.errorMessage.value.isNotEmpty
                                            ? stockCtrl.errorMessage.value
                                            : 'Failed to save category',
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: CheckoutTokens.accent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isEdit ? 'Update' : 'Create',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _buildImagePreview({String? pickedPath, String? existingUrl}) {
  if (pickedPath != null && pickedPath.isNotEmpty) {
    return Image.file(
      File(pickedPath),
      fit: BoxFit.cover,
    );
  }

  if (existingUrl != null && existingUrl.isNotEmpty) {
    return Image.network(
      existingUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _UploadPromptPlaceholder(),
    );
  }

  return const _UploadPromptPlaceholder();
}

class _UploadPromptPlaceholder extends StatelessWidget {
  const _UploadPromptPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.15),
      alignment: Alignment.center,
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CheckoutTokens.accentSoft,
            ),
            child: Icon(
              Icons.image_outlined,
              color: CheckoutTokens.accent,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload category image',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Optional · PNG or JPG recommended',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
