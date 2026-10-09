import '../../../../core/utils/invoice_amount.dart';

class OutstandingInvoice {
  const OutstandingInvoice({
    required this.id,
    required this.reference,
    required this.due,
    this.date = '',
    this.currency = '',
  });
  final String id;
  final String reference;
  final double due;
  final String date;
  final String currency;

  static List<OutstandingInvoice> fromResponse(dynamic response) {
    final data = response is Map ? response['data'] : null;
    final invoices = data is List
        ? data
        : data is Map
        ? data['invoices']
        : null;
    if (invoices is! List) {
      throw const FormatException('Invalid customer balance response');
    }
    final seen = <String>{};
    final result = <OutstandingInvoice>[];
    double money(dynamic value) {
      final number = value is num
          ? value.toDouble()
          : double.tryParse('$value');
      if (number == null || !number.isFinite || number < 0) {
        throw const FormatException('Invalid invoice amount');
      }
      return invoiceMoney(number);
    }

    for (final invoice in invoices.whereType<Map>()) {
      final type = '${invoice['type'] ?? ''}'.toLowerCase();
      if (['purchase', 'refund', 'delivery'].any(type.contains)) continue;
      final details = invoice['paymentDetails'];
      final total = money(invoice['totalAmount'] ?? 0);
      final paid = money(
        invoice['amountPaid'] ??
            (details is Map ? details['amountPaid'] : null) ??
            (invoice['paymentStatus'] == 'paid' ? total : 0),
      );
      final rawDue =
          invoice['dueAmount'] ??
          (details is Map ? details['dueAmount'] : null);
      final due = rawDue == null
          ? invoiceMoney((total - paid).clamp(0, total).toDouble())
          : money(rawDue);
      if (due <= 0) continue;
      final id = '${invoice['_id'] ?? invoice['id'] ?? ''}';
      if (id.isEmpty) {
        throw const FormatException('Invoice reference is missing');
      }
      if (!seen.add(id)) continue;
      result.add(
        OutstandingInvoice(
          id: id,
          reference: '${invoice['invoiceNumber'] ?? id}',
          due: due,
          date: '${invoice['createdAt'] ?? ''}',
          currency: '${invoice['currency'] ?? ''}'.toUpperCase(),
        ),
      );
    }
    return result;
  }
}
