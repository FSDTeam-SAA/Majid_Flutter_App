class OrderReadyItem {
  final String customerName;
  final String itemDescription;
  final String readySince;
  final double price;

  const OrderReadyItem({
    required this.customerName,
    required this.itemDescription,
    required this.readySince,
    required this.price,
  });

  String get initials {
    final parts = customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}

/// Placeholder sample data until the "ready for collection" endpoint exists —
/// swap for a repository call once the repair-complete → orders handoff is
/// wired up on the backend.
const sampleReadyOrders = [
  OrderReadyItem(
    customerName: 'Muhammad Majid',
    itemDescription: 'iPad Air – Screen Repair',
    readySince: 'Ready since Jun 04, 2026',
    price: 89.00,
  ),
  OrderReadyItem(
    customerName: 'Sarah Johnson',
    itemDescription: 'Samsung S23 – Battery Replacement',
    readySince: 'Ready since Jun 05, 2026',
    price: 45.50,
  ),
  OrderReadyItem(
    customerName: 'David Lee',
    itemDescription: 'Pixel 8 – Charging Port Fix',
    readySince: 'Ready since Jun 06, 2026',
    price: 32.00,
  ),
];
