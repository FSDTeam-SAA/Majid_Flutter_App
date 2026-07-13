/// A subscription/pricing plan shown on the upgrade plan page.
class SubscriptionPlan {
  final String id;
  final String type;
  final String name;
  final String description;
  final String? priceLabel;
  final double price;
  final bool customPricing;
  final bool isPopular;
  final num? discount;
  final String? ctaText;

  /// Names of the features that are marked as included on this plan (the
  /// upgrade plan page never shows non-included features, so the repository
  /// pre-filters them here instead of the page reading `features[i].included`).
  final List<String> includedFeatures;

  const SubscriptionPlan({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.priceLabel,
    required this.price,
    required this.customPricing,
    required this.isPopular,
    required this.discount,
    required this.ctaText,
    required this.includedFeatures,
  });
}
