import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart' show baseUrl;
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../invoice/presentation/pages/invoice_page.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';

class CartItemsPage extends StatefulWidget {
  const CartItemsPage({super.key});

  @override
  State<CartItemsPage> createState() => _CartItemsPageState();
}

class _CartItemsPageState extends State<CartItemsPage> {
  late final CartRepository _cartRepo;
  late final ProfileController _profileCtrl;
  final TextEditingController _searchCtrl = TextEditingController();

  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cartRepo = CartRepositoryImpl(ApiClient(baseUrl));
    _profileCtrl = Get.find<ProfileController>();
    fetchCartItems();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<String?> _resolveShopkeeperId() async {
    var userId = _profileCtrl.userId;
    if (userId.isEmpty) {
      await _profileCtrl.fetchProfile();
      userId = _profileCtrl.userId;
    }
    return userId.isEmpty ? null : userId;
  }

  Future<void> fetchCartItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final shopkeeperId = await _resolveShopkeeperId();
      if (shopkeeperId == null) {
        throw Exception('Unable to find your profile');
      }

      final items = await _cartRepo.getCartItems(shopkeeperId);
      setState(() {
        _cartItems = items;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data?['message'] ?? 'Failed to load cart items';
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCartItem(String cartId) async {
    try {
      await _cartRepo.deleteCartItem(cartId);
      _cartItems.removeWhere((item) => item.id == cartId);
      if (!mounted) return;
      setState(() {});
      showSuccessSnackbar('Cart item removed');
    } on DioException catch (e) {
      showErrorSnackbar(
        e.response?.data?['message'] ?? 'Failed to remove cart item',
      );
    }
  }

  List<CartItem> get _filteredItems {
    return _cartItems.where((entry) {
      final item = entry.item;
      final haystack = [
        item?.itemName,
        item?.brand,
        item?.imeiNumber,
        item?.storage,
        item?.color,
      ].whereType<String>().join(' ').toLowerCase();

      return _searchQuery.isEmpty || haystack.contains(_searchQuery);
    }).toList();
  }

  int get _totalUnits {
    return _filteredItems.fold<int>(0, (sum, entry) => sum + entry.quantity);
  }

  double get _totalValue {
    return _filteredItems.fold<double>(0, (sum, entry) {
      return sum + entry.totalPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context),
                  _buildSearchBar(),
                  _buildSummaryHeader(),
                  _buildStatsRow(),
                  SizedBox(height: 8),
                  Expanded(child: _buildBody()),
                ],
              ),
              if (_filteredItems.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildBottomBar(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: Row(
        children: [
          _CircleActionButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              'Cart Items',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.fieldBackground,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.primary.withValues(
              alpha: AppColors.isDark ? 0.6 : 0.72,
            ),
          ),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (value) =>
              setState(() => _searchQuery = value.trim().toLowerCase()),
          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Search cart items...',
            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$_totalUnits units in cart (${_filteredItems.length} models)',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(
              alpha: AppColors.isDark ? 0.92 : 0.78,
            ),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatBox(label: 'MODELS', value: '${_filteredItems.length}'),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatBox(label: 'UNITS', value: '$_totalUnits'),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _StatBox(label: 'VALUE', value: _formatPrice(_totalValue)),
          ),
        ],
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
                style: TextStyle(color: AppColors.textSecondary),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchCartItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surfaceForeground,
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
        onRefresh: fetchCartItems,
        child: ListView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, 80, 24, 120),
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.textSecondary,
              size: 56,
            ),
            SizedBox(height: 14),
            Text(
              'No cart items found',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      onRefresh: fetchCartItems,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: _filteredItems.length,
        separatorBuilder: (_, _) => SizedBox(height: 14),
        itemBuilder: (context, index) {
          final entry = _filteredItems[index];
          return _CartItemCard(
            entry: entry,
            onDelete: () => _deleteCartItem(entry.id),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => Get.to(() => InvoicePage()),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surfaceForeground,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            'Preview Invoice',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  static String _formatPrice(double value) {
    final hasFraction = value % 1 != 0;
    return '\$${value.toStringAsFixed(hasFraction ? 2 : 0)}';
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem entry;
  final VoidCallback onDelete;

  const _CartItemCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final item = entry.item;
    final title = item?.itemName ?? 'Unnamed Item';
    final brand = item?.brand ?? 'Unknown Brand';
    final storage = item?.storage ?? '';
    final color = item?.color ?? '';
    final imei = item != null && item.imeiNumber.isNotEmpty ? item.imeiNumber : 'No IMEI';
    final condition = (item?.currentState ?? 'new').toUpperCase();
    final imageUrl = item?.imageUrl;
    final quantity = entry.quantity;
    final unitPrice = entry.unitPrice;
    final totalPrice = entry.totalPrice;
    final createdAt = entry.createdAt;

    final isDark = AppColors.isDark;
    final cardBackground = isDark
        ? AppColors.cardBackground
        : const Color(0x80FFFFFF);
    final cardBorder = isDark ? AppColors.fieldBorder : const Color(0xFFE4E7EC);
    final lightMetaColor = const Color(0xFF6C7892);
    final lightMutedColor = const Color(0xFF7E889F);
    final lightDateColor = const Color(0xFF1FC16B);
    final detailTextColor = isDark
        ? AppColors.textSecondary
        : const Color(0xFF667085);
    final lightShadowColor = const Color(0xFF111827).withValues(alpha: 0.04);
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorder),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: lightShadowColor,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CartImage(imageUrl: imageUrl),
              SizedBox(width: 12),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      [
                        brand,
                        storage,
                        color,
                      ].where((e) => e.isNotEmpty).join(' • '),
                      style: TextStyle(
                        color: detailTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'IMEI:  $imei',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFA8B4C5) : lightMetaColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        _MetaPill(
                          label: condition,
                          color: AppColors.primary,
                          background: AppColors.primary.withValues(alpha: 0.12),
                        ),
                        SizedBox(width: 8),
                        if (createdAt != null)
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              color: lightDateColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_vert,
                color: isDark ? const Color(0xFF8895A7) : lightMutedColor,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: cardBorder, height: 1),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PriceBox(
                  label: 'UNIT PRICE',
                  value: _CartItemsPageState._formatPrice(unitPrice),
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: _PriceBox(
                  label: 'TOTAL PRICE',
                  value: _CartItemsPageState._formatPrice(totalPrice),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.fieldBackground
                      : const Color(0xFFF7F9FD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cardBorder),
                ),
                child: Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.fieldBorder
                          : const Color(0xFFF0D7D7),
                    ),
                    color: isDark
                        ? AppColors.fieldBackground
                        : const Color(0xFFFFF6F6),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: isDark
                        ? AppColors.textPrimary
                        : const Color(0xFFE05A5A),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Container(
      height: 84,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackground : const Color(0x80FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.fieldBorder : const Color(0xFFE4E7EC),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String value;

  const _PriceBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.fieldBackground : const Color(0x66FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.fieldBorder : const Color(0xFFE4E7EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.textSecondary : const Color(0xFF6C7892),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const _MetaPill({
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1,
        ),
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  final String? imageUrl;

  const _CartImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark;
    return Container(
      width: 76,
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.fieldBorder : const Color(0xFFE4E7EC),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFF7FAFD),
      child: Icon(
        Icons.phone_iphone_rounded,
        color: const Color(0xFF7C8AA0),
        size: 42,
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
          color: AppColors.fieldBackground,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 21),
      ),
    );
  }
}
