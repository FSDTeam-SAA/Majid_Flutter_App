/// A stock category (e.g. "Phones", "Accessories") shown on the stock
/// dashboard grid and used to group inventory items.
///
/// [itemCount] is backend-computed (via `CategoryEndpoints.withCount`) but
/// may also be client-derived by merging in inventory items that reference
/// a category the backend count endpoint didn't return yet (see
/// `StockController._buildInventoryCategoryCards`), which is why it is a
/// plain mutable-via-[copyWith] field rather than something the entity
/// computes itself.
class Category {
  final String id;
  final String name;
  final String? imageUrl;
  final int itemCount;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.itemCount = 0,
  });

  Category copyWith({String? name, String? imageUrl, int? itemCount}) {
    return Category(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}
