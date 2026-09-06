/// Lightweight entity representing an invoice as shown in the "View
/// Invoices" tab. Mirrors the fields the UI previously read directly off
/// the raw JSON map returned by the invoices list endpoint.
class Invoice {
  final String id;
  final String type;
  final double? totalAmount;
  final double? amountPaid;
  final String? createdAt;
  final String customerName;
  final String? customerPhone;
  final String? pdfUrl;
  final String? paymentMethod;
  final String? paymentStatus;

  const Invoice({
    required this.id,
    required this.type,
    this.totalAmount,
    this.amountPaid,
    this.createdAt,
    required this.customerName,
    this.customerPhone,
    this.pdfUrl,
    this.paymentMethod,
    this.paymentStatus,
  });

  /// Short reference shown in the invoice list, e.g. `#INV-9884BD5A` - the
  /// last 8 characters of the Mongo id, matching the website's registry.
  String get reference {
    final tail = id.length >= 8 ? id.substring(id.length - 8) : id;
    return '#INV-${tail.toUpperCase()}';
  }

  /// Human label for [type], matching the website's classification badges.
  ///
  /// Matched with `contains` rather than an exact switch: the app sends short
  /// codes when it creates an invoice ('purchase', 'delivery'), but invoices
  /// created elsewhere (the website) store the type as a full phrase already
  /// ("Purchase Invoice", "Delivery Note"). An exact match against 'purchase'
  /// missed those and silently classified every one of them as "Custom
  /// Invoice" instead.
  String get classification {
    final value = type.toLowerCase();
    if (value.contains('purchase')) return 'Purchase Invoice';
    if (value.contains('delivery')) return 'Delivery Note';
    return 'Custom Invoice';
  }

  /// The website only offers a refund on customer-facing sales invoices, not
  /// purchase or delivery paperwork.
  bool get isRefundable => classification == 'Custom Invoice';
}
