import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import 'add_category_sheet.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  final List<_ManagedCategory> _categories = [
    _ManagedCategory(name: 'Phones', icon: Icons.smartphone, colorHex: 0xFFD4A853),
    _ManagedCategory(name: 'Tablets', icon: Icons.tablet_mac, colorHex: 0xFF9B8EC4),
    _ManagedCategory(name: 'Laptops', icon: Icons.laptop_mac, colorHex: 0xFF5B8DEF),
    _ManagedCategory(name: 'Gaming', icon: Icons.sports_esports_outlined, colorHex: 0xFFE0E0E0),
    _ManagedCategory(name: 'Accessories', icon: Icons.headphones, colorHex: 0xFF4DB8FF),
    _ManagedCategory(name: 'Repairing', icon: Icons.build_outlined, colorHex: 0xFF888888),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1F2D), Color(0xFF060E0B)],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: Text(
                  '${_categories.length} Categories Available',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) => _buildCategoryCard(_categories[i], i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 16),
            ),
          ),
          const Expanded(
            child: Text(
              'Manage Categories',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
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
            child: const Icon(Icons.menu, color: AppColors.textPrimary, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_ManagedCategory cat, int index) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111A24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2840)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                color: Color(cat.colorHex).withValues(alpha: 0.12),
                child: Icon(cat.icon, color: Color(cat.colorHex), size: 64),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cat.name,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                _buildIconBtn(
                  icon: Icons.edit_outlined,
                  color: Colors.white,
                  onTap: () => showAddCategorySheet(context, existingName: cat.name),
                ),
                const SizedBox(width: 6),
                _buildIconBtn(
                  icon: Icons.delete_outline_rounded,
                  color: const Color(0xFFFF4444),
                  onTap: () => _confirmDelete(context, index),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${_categories[index].name}"?',
          style: const TextStyle(color: Color(0xFF7A8A85)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white))),
          TextButton(
            onPressed: () {
              setState(() => _categories.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF4444))),
          ),
        ],
      ),
    );
  }
}

class _ManagedCategory {
  final String name;
  final IconData icon;
  final int colorHex;
  const _ManagedCategory({required this.name, required this.icon, required this.colorHex});
}
