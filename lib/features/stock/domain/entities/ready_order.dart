import '../../../../core/utils/invoice_amount.dart';

/// A repair the technician has finished, waiting to be collected and paid for.
///
/// Sourced from `GET /repair-requests/completed`.
class ReadyOrder {
  final String id;
  final String customerName;

  /// Contact details as recorded on the repair, used to match the order back
  /// to a saved customer at checkout.
  final String customerPhone;
  final String customerEmail;
  final String deviceModel;
  final double price;
  final DateTime? completedAt;

  const ReadyOrder({
    required this.id,
    required this.customerName,
    required this.deviceModel,
    required this.price,
    this.customerPhone = '',
    this.customerEmail = '',
    this.completedAt,
  });

  factory ReadyOrder.fromJson(Map<String, dynamic> json) {
    return ReadyOrder(
      id: json['_id']?.toString() ?? '',
      customerName: json['firstName']?.toString().trim() ?? 'Customer',
      customerPhone: json['phoneNumber']?.toString().trim() ?? '',
      customerEmail: json['email']?.toString().trim() ?? '',
      deviceModel: json['deviceModel']?.toString().trim() ?? 'Device',
      price: invoiceMoney(
        (totalPrice(json) - depositPaid(json))
            .clamp(0, double.infinity)
            .toDouble(),
      ),
      completedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  /// Used by both the collection checkout and the repair receipt.
  static double totalPrice(Map<String, dynamic> json) {
    final rawDiscount = _number(json['discount']);
    final discount = rawDiscount.clamp(0, 100);
    return invoiceMoney(_resolvePrice(json) * (1 - discount / 100));
  }

  static double depositPaid(Map<String, dynamic> json) => invoiceMoney(
    _number(json['depositPaid']).clamp(0, totalPrice(json)).toDouble(),
  );

  static double _number(dynamic value) {
    final number = value is num ? value.toDouble() : double.tryParse('$value');
    return number != null && number.isFinite && number >= 0 ? number : 0;
  }

  /// Round-trips this order through the saved checkout draft. Keys match
  /// [ReadyOrder.fromJson] so the API response and a restored draft parse the
  /// same way.
  Map<String, dynamic> toJson() => {
    '_id': id,
    'firstName': customerName,
    'phoneNumber': customerPhone,
    'email': customerEmail,
    'deviceModel': deviceModel,
    'price': price,
    'updatedAt': completedAt?.toIso8601String(),
  };

  /// The shopkeeper's quote wins; otherwise fall back to the technician's
  /// parts costs, which is all the backend records for some repairs.
  static double _resolvePrice(Map<String, dynamic> json) {
    final direct = _number(json['price']);
    if (direct > 0) return direct;

    final notes = json['shopkeeperNotes'];
    if (notes is Map) {
      final cost = _number(notes['cost']);
      if (cost > 0) return cost;
    }

    final techNotes = json['technicianNotes'];
    if (techNotes is List) {
      final total = techNotes.whereType<Map>().fold<double>(
        0,
        (sum, note) => sum + _number(note['cost']),
      );
      if (total > 0) return total;
    }
    return 0;
  }

  /// Short human readable handle, e.g. `#173D4F34`.
  String get reference {
    if (id.length < 8) return id.isEmpty ? '#------' : '#${id.toUpperCase()}';
    return '#${id.substring(id.length - 8).toUpperCase()}';
  }

  /// `10/08/2026`, matching the web checkout.
  String get completedLabel {
    final date = completedAt;
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String get initials {
    final parts = customerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
