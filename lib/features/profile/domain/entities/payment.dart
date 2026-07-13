/// A single payment/transaction entry, as shown on the payment history page.
class Payment {
  final String id;
  final double amount;
  final String status;
  final DateTime? createdAt;

  const Payment({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
  });
}
