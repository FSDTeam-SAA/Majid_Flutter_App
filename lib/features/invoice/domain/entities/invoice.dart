/// Lightweight entity representing an invoice as shown in the "View
/// Invoices" tab. Mirrors the fields the UI previously read directly off
/// the raw JSON map returned by the invoices list endpoint.
class Invoice {
  final String id;
  final String? invoiceNumber;
  final String type;
  final double? totalAmount;
  final double? amountPaid;
  final String? createdAt;
  final String customerName;
  final String? customerId;
  final String? customerEmail;
  final String? customerPhone;
  final String? pdfUrl;
  final String? paymentMethod;
  final String? paymentStatus;

  const Invoice({
    required this.id,
    this.invoiceNumber,
    required this.type,
    this.totalAmount,
    this.amountPaid,
    this.createdAt,
    required this.customerName,
    this.customerId,
    this.customerEmail,
    this.customerPhone,
    this.pdfUrl,
    this.paymentMethod,
    this.paymentStatus,
  });

  /// The original invoice number when recorded, or an ID-based fallback.
  String get reference {
    if (invoiceNumber?.trim().isNotEmpty ?? false) {
      return invoiceNumber!.trim();
    }
    final tail = id.length >= 8 ? id.substring(id.length - 8) : id;
    return '#INV-${tail.toUpperCase()}';
  }

  /// Purchase paperwork is always money leaving the business. Keep this
  /// normalization on the entity so transaction lists and reports cannot
  /// disagree when the API returns either `purchase`, `Purchase Invoice`, or
  /// another purchase-labelled legacy value.
  bool get isPurchase => type.trim().toLowerCase().contains('purchase');

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
    if (isPurchase) return 'Purchase Invoice';
    if (value.contains('delivery')) return 'Delivery Note';
    return 'Custom Invoice';
  }

  /// The website only offers a refund on customer-facing sales invoices, not
  /// purchase or delivery paperwork.
  bool get isRefundable => classification == 'Custom Invoice';
}
