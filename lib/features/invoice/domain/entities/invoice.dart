/// Lightweight entity representing an invoice as shown in the "View
/// Invoices" tab. Mirrors the fields the UI previously read directly off
/// the raw JSON map returned by the invoices list endpoint.
class Invoice {
  final String id;
  final String type;
  final double? totalAmount;
  final String? createdAt;
  final String customerName;
  final String? pdfUrl;

  const Invoice({
    required this.id,
    required this.type,
    this.totalAmount,
    this.createdAt,
    required this.customerName,
    this.pdfUrl,
  });
}
