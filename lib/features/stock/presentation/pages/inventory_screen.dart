import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/presentation/controller/auth_controller.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../controller/stock_controller.dart';
import 'add_new_device_page.dart';
import 'cart_items_page.dart';

class InventoryScreen extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialCategoryName;

  const InventoryScreen({
    super.key,
    this.initialCategoryId,
    this.initialCategoryName,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final ApiClient _api;
  late final AuthController _authCtrl;
  late final StockController _stockCtrl;
  late final ProfileController _profileCtrl;
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _authCtrl = Get.find<AuthController>();
    _stockCtrl = Get.find<StockController>();
    _profileCtrl = Get.find<ProfileController>();
    _selectedCategoryId = widget.initialCategoryId;
    _primeCategories();
    fetchInventory();
  }

  Future<void> _primeCategories() async {
    if (_stockCtrl.categories.isNotEmpty) return;
    await _stockCtrl.fetchCategories();
    if (mounted) setState(() {});
  }

  Future<String?> _resolveShopkeeperId() async {
    var userId = _authCtrl.user.value?.id ?? '';
    if (userId.isEmpty) {
      userId = _profileCtrl.userId;
    }
    if (userId.isEmpty) {
      await _profileCtrl.fetchProfile();
      userId = _profileCtrl.userId;
    }
    return userId.isEmpty ? null : userId;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<int> fetchInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final res = await _api.get(InventoryEndpoints.myInventory);
      final data = res.data['data'];
      final List<Map<String, dynamic>> items = data is List
          ? List<Map<String, dynamic>>.from(data)
          : <Map<String, dynamic>>[];
      setState(() {
        _items = items;
      });
      return items.length;
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data?['message'] ?? 'Failed to load inventory';
      });
      return 0;
    } catch (_) {
      setState(() => _errorMessage = 'Failed to load inventory');
      return 0;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    return _items.where((item) {
      final itemCategoryId = _categoryIdOf(item);
      final matchesCategory =
          _selectedCategoryId == null || itemCategoryId == _selectedCategoryId;

      final haystack = [
        item['itemName'],
        item['brand'],
        item['imeiNumber'],
        item['modelNumber'],
        item['storage'],
        item['color'],
      ].whereType<String>().join(' ').toLowerCase();

      final matchesSearch =
          _searchQuery.isEmpty || haystack.contains(_searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get _totalUnitsInStock {
    return _filteredItems.fold<int>(0, (sum, item) {
      final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
      return sum + quantity;
    });
  }

  double get _totalRevenuePotential {
    return _filteredItems.fold<double>(0, (sum, item) {
      final rawQuantity = (item['quantity'] as num?)?.toInt() ?? 0;
      final quantity = rawQuantity < 0
          ? 0
          : (rawQuantity > 999 ? 999 : rawQuantity);
      final expectedPrice =
          (item['expectedPrice'] as num?)?.toDouble() ??
          (item['purchasePrice'] as num?)?.toDouble() ??
          0;
      return sum + (quantity > 0 ? expectedPrice * quantity : expectedPrice);
    });
  }

  String? _categoryIdOf(Map<String, dynamic> item) {
    final categoryId = item['categoryId'];
    if (categoryId is String) return categoryId;
    if (categoryId is Map && categoryId['_id'] is String) {
      return categoryId['_id'] as String;
    }
    return null;
  }

  Map<String, dynamic>? _findCategoryById(String? id) {
    if (id == null) return null;
    for (final category in _stockCtrl.categories) {
      if (category['_id']?.toString() == id) {
        return category;
      }
    }
    return null;
  }

  String _selectedCategoryLabel() {
    if (_selectedCategoryId == null) return 'Category';

    final category = _findCategoryById(_selectedCategoryId);
    if (category != null && category['name'] is String) {
      return category['name'] as String;
    }
    return widget.initialCategoryName ?? 'Category';
  }

  String _categoryNameOf(Map<String, dynamic> item) {
    final categoryId = _categoryIdOf(item);
    if (categoryId == null) return 'Uncategorized';
    final category = _findCategoryById(categoryId);
    return category?['name']?.toString() ?? 'Uncategorized';
  }

  Future<void> _openCategoryPicker() async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Color(0xFF0D171C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final categories = _stockCtrl.categories;
        final maxHeight = MediaQuery.of(context).size.height * 0.72;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Category',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        _CategoryOptionTile(
                          title: 'All Categories',
                          isSelected: _selectedCategoryId == null,
                          onTap: () => Navigator.pop(context, null),
                        ),
                        SizedBox(height: 8),
                        ...categories.map(
                          (category) => Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: _CategoryOptionTile(
                              title: category['name']?.toString() ?? 'Unnamed',
                              subtitle:
                                  '${category['itemCount'] ?? category['totalItems'] ?? 0} items',
                              isSelected:
                                  _selectedCategoryId == category['_id'],
                              onTap: () => Navigator.pop(
                                context,
                                category['_id']?.toString(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _selectedCategoryId = selected);
  }

  Future<void> _addItemToCart(Map<String, dynamic> item) async {
    final itemId = item['_id']?.toString() ?? item['id']?.toString();
    if (itemId == null || itemId.isEmpty) {
      showErrorSnackbar('Invalid inventory item');
      return;
    }

    try {
      final shopkeeperId = await _resolveShopkeeperId();
      if (shopkeeperId == null) {
        showErrorSnackbar('Unable to find your profile');
        return;
      }

      await _api.post(
        CartEndpoints.create,
        data: {'shopkeeperId': shopkeeperId, 'itemId': itemId, 'quantity': 1},
      );
      if (!mounted) return;
      showSuccessSnackbar('Added to cart');
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message']?.toString()
          : null;
      showErrorSnackbar(message ?? e.message ?? 'Failed to add to cart');
    } catch (_) {
      showErrorSnackbar('Failed to add to cart');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildFilters(),
              _buildSummary(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          _CircleActionButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              'Inventory',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _CircleActionButton(
            icon: Icons.shopping_cart_outlined,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CartItemsPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: Color(0x0CFFFFFF),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim().toLowerCase()),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  hintText: 'Search items...',
                  hintStyle: TextStyle(color: AppColors.primary, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 17),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          GestureDetector(
            onTap: _openCategoryPicker,
            child: Container(
              height: 58,
              padding: EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    _selectedCategoryLabel(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.black,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$_totalUnitsInStock Units in Stock (${_filteredItems.length} Models) - ${_formatCurrency(_totalRevenuePotential)} Total Revenue Potential',
          style: TextStyle(
            color: Color(0xFFD8E1E8),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_tethering_error_rounded,
                color: AppColors.textSecondary,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              SizedBox(height: 18),
              ElevatedButton(
                onPressed: fetchInventory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredItems.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardBackground,
        onRefresh: fetchInventory,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, 80, 24, 120),
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textSecondary,
              size: 56,
            ),
            SizedBox(height: 14),
            Text(
              'No inventory items found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try another category or search term, or add products to your stock first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            SizedBox(height: 18),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final created = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddNewDevicePage(
                        initialCategoryId: _selectedCategoryId,
                        initialCategoryName: _selectedCategoryLabel(),
                      ),
                    ),
                  );
                  if (!context.mounted || created != true) return;
                  await fetchInventory();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                icon: Icon(Icons.add_rounded),
                label: Text(
                  'Add New Device',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      onRefresh: fetchInventory,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 120),
        itemCount: _filteredItems.length,
        separatorBuilder: (_, _) => SizedBox(height: 18),
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _InventoryCard(
            item: item,
            categoryName: _categoryNameOf(item),
            onAddToCart: () => _addItemToCart(item),
          );
        },
      ),
    );
  }

  String _formatCurrency(num value) {
    final safeValue = value.isFinite ? value : 0;
    final hasFraction = safeValue % 1 != 0;
    return '\$${safeValue.toStringAsFixed(hasFraction ? 2 : 0)}';
  }
}

class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String categoryName;
  final VoidCallback onAddToCart;

  const _InventoryCard({
    required this.item,
    required this.categoryName,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final title = item['itemName']?.toString().trim().isNotEmpty == true
        ? item['itemName'].toString()
        : 'Unnamed Item';
    final brand = item['brand']?.toString() ?? 'Unknown Brand';
    final storage = item['storage']?.toString() ?? '';
    final color = item['color']?.toString() ?? '';
    final imei = item['imeiNumber']?.toString() ?? 'No IMEI';
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    final price =
        (item['expectedPrice'] as num?)?.toDouble() ??
        (item['purchasePrice'] as num?)?.toDouble() ??
        0;
    final imageUrl = item['image'] is Map
        ? item['image']['url']?.toString()
        : null;
    final currentState = item['currentState']?.toString() ?? '';
    final status = item['status']?.toString() ?? 'inventory';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InventoryImage(imageUrl: imageUrl),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      [
                        brand,
                        storage,
                        color,
                      ].where((e) => e.isNotEmpty).join(' • '),
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      imei,
                      style: TextStyle(
                        color: Color(0xFFA8B4C5),
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (currentState.isNotEmpty)
                          _StatusPill(
                            label: currentState.toUpperCase(),
                            color: Color(0xFF5D88FF),
                            background: Color(0x131B48FF),
                          ),
                        _StatusPill(
                          label: _statusLabel(status),
                          color: _statusColor(status),
                          background: _statusColor(
                            status,
                          ).withValues(alpha: 0.14),
                        ),
                        _StatusPill(
                          label: categoryName.toUpperCase(),
                          color: Color(0xFFA4B4BE),
                          background: Color(0x142E3B46),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.more_vert, color: Color(0xFF8895A7)),
            ],
          ),
          SizedBox(height: 18),
          Divider(color: AppColors.fieldBorder, height: 1),
          SizedBox(height: 14),
          Row(
            children: [
              Text(
                _formatPrice(price),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF0A131C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    color: Color(0xFFD9E3EE),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: onAddToCart,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Color(0xFF252F40),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_cart_checkout_outlined,
                    color: Color(0xFFE6EEF8),
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double value) {
    final hasFraction = value % 1 != 0;
    return '\$${value.toStringAsFixed(hasFraction ? 2 : 0)}';
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'sold':
        return 'SOLD';
      case 'draft':
        return 'DRAFT';
      case 'due':
        return 'DUE';
      default:
        return 'IN STOCK';
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'sold':
        return Color(0xFFE98A8A);
      case 'draft':
        return Color(0xFFF5C96E);
      case 'due':
        return Color(0xFFB58AFF);
      default:
        return Color(0xFF35D46F);
    }
  }
}

class _InventoryImage extends StatelessWidget {
  final String? imageUrl;

  const _InventoryImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 118,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: Color(0xFFF0F5FA),
      child: Icon(
        Icons.phone_iphone_rounded,
        color: Color(0xFF7C8AA0),
        size: 42,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CategoryOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryOptionTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF12211B) : Color(0xFF101A22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Color(0xFF23313A),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.fieldBorder,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }
}
