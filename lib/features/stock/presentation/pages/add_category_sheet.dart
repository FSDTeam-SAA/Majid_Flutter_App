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
  String? currentImageUrl = existingImageUrl;
  bool isImageRemoved = false;
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
              ],
            ),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit Category' : 'Create Category',
                            style: CheckoutTokens.text(
                              size: 20,
                              weight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Categories organize inventory before products are shown.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                  const SizedBox(height: 18),

                  // Image label
                  Text(
                    'CATEGORY IMAGE',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Image container
                  Container(
                    width: double.infinity,
                    height: 170,
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.fieldBorder,
                        width: 1.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: _buildImagePreview(
                              pickedPath: pickedImagePath,
                              existingUrl: isImageRemoved ? null : currentImageUrl,
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        pickedImagePath = picked.path;
                                        isImageRemoved = false;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                                  label: Text(
                                    (pickedImagePath != null || (!isImageRemoved && currentImageUrl != null))
                                        ? 'Change'
                                        : 'Upload Photo',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: CheckoutTokens.accent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                                if (pickedImagePath != null ||
                                    (!isImageRemoved &&
                                        currentImageUrl != null &&
                                        currentImageUrl.isNotEmpty)) ...[
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setDialogState(() {
                                        pickedImagePath = null;
                                        isImageRemoved = true;
                                      });
                                    },
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                    label: const Text(
                                      'Remove',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.dangerColor,
                                      side: BorderSide(
                                        color: AppColors.dangerColor.withValues(alpha: 0.5),
                                      ),
                                      backgroundColor: AppColors.cardBackground.withValues(alpha: 0.9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
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
