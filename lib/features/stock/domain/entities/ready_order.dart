/// A repair the technician has finished, waiting to be collected and paid for.
///
/// Sourced from `GET /repair-requests/completed`.
class ReadyOrder {
  final String id;
  final String customerName;
  final String deviceModel;
  final double price;
  final DateTime? completedAt;

  const ReadyOrder({
    required this.id,
    required this.customerName,
    required this.deviceModel,
    required this.price,
    this.completedAt,
  });

  factory ReadyOrder.fromJson(Map<String, dynamic> json) {
    return ReadyOrder(
      id: json['_id']?.toString() ?? '',
      customerName: json['firstName']?.toString().trim() ?? 'Customer',
      deviceModel: json['deviceModel']?.toString().trim() ?? 'Device',
      price: _resolvePrice(json),
      completedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  /// The shopkeeper's quote wins; otherwise fall back to the technician's
  /// parts costs, which is all the backend records for some repairs.
  static double _resolvePrice(Map<String, dynamic> json) {
    final direct = (json['price'] as num?)?.toDouble();
    if (direct != null && direct > 0) return direct;

    final notes = json['shopkeeperNotes'];
    if (notes is Map) {
      final cost = (notes['cost'] as num?)?.toDouble();
      if (cost != null && cost > 0) return cost;
    }

    final techNotes = json['technicianNotes'];
    if (techNotes is List) {
      final total = techNotes.whereType<Map>().fold<double>(
        0,
        (sum, note) => sum + ((note['cost'] as num?)?.toDouble() ?? 0),
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
