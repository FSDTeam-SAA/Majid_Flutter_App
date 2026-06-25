import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../controller/stock_controller.dart';
import 'add_category_sheet.dart';

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final stockCtrl = Get.find<StockController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Obx(
                  () => Text(
                    '${stockCtrl.categories.length} Categories Available',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (stockCtrl.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (stockCtrl.categories.isEmpty) {
                    return Center(
                      child: Text(
                        'No categories yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 30),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: stockCtrl.categories.length,
                    itemBuilder: (context, i) {
                      final cat = stockCtrl.categories[i];
                      return _buildCategoryCard(context, cat, stockCtrl);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Manage Categories',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.fieldBorder),
            ),
            child: Icon(Icons.menu, color: AppColors.textPrimary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> cat,
    StockController stockCtrl,
  ) {
    final name = cat['name'] ?? '';
    final imageUrl = cat['image'] is Map ? cat['image']['url'] : null;
    final id = cat['_id'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                color: Color(0xFF0D1E2E),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.category_outlined,
                          color: Colors.white24,
                          size: 64,
                        ),
                      )
                    : Icon(
                        Icons.category_outlined,
                        color: Colors.white24,
                        size: 64,
                      ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildIconBtn(
                  icon: Icons.edit_outlined,
                  color: Colors.white,
                  onTap: () => showAddCategorySheet(
                    context,
                    existingId: id,
                    existingName: name,
                    existingImageUrl: imageUrl,
                  ),
                ),
                SizedBox(width: 6),
                _buildIconBtn(
                  icon: Icons.delete_outline_rounded,
                  color: Color(0xFFFF4444),
                  onTap: () => _confirmDelete(context, id, name, stockCtrl),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String id,
    String name,
    StockController stockCtrl,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Category',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: TextStyle(color: Color(0xFF7A8A85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await stockCtrl.deleteCategory(id);
              if (success) {
                showSuccessSnackbar('Category deleted');
              } else {
                showErrorSnackbar(stockCtrl.errorMessage.value);
              }
            },
            child: Text('Delete', style: TextStyle(color: Color(0xFFFF4444))),
          ),
        ],
      ),
    );
  }
}
