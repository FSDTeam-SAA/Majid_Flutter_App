import '../../../invoice/domain/entities/invoice.dart';
import '../../domain/entities/transaction_entry.dart';

TransactionEntry transactionFromInvoice(Invoice invoice) {
  final refund =
      invoice.type.toLowerCase().contains('refund') ||
      (invoice.paymentStatus ?? '').toLowerCase().contains('refund');
  final method = (invoice.paymentMethod ?? '').toLowerCase();
  final card = ['card', 'bank', 'transfer'].any(method.contains);
  final kind = invoice.isPurchase
      ? TransactionKind.expense
      : refund
      ? TransactionKind.refund
      : card
      ? TransactionKind.cardReceived
      : TransactionKind.cashReceived;
  final date = DateTime.tryParse(invoice.createdAt ?? '')?.toLocal();
  final amount =
      invoice.amountPaid ??
      ((invoice.paymentStatus ?? '').toLowerCase() == 'due'
          ? 0
          : invoice.totalAmount ?? 0);
  final name = invoice.customerName.trim().toUpperCase() == 'N/A'
      ? ''
      : invoice.customerName.trim();
  return TransactionEntry(
    title: invoice.isPurchase
        ? 'Inventory Purchase'
        : refund
        ? 'Refund Issued'
        : card
        ? 'Card Payment Received'
        : 'Cash Received',
    subtitle:
        '${name.isEmpty ? 'Walk-in customer' : name} · ${invoice.classification}',
    time: date == null
        ? 'Date not recorded'
        : '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
    amount: (invoice.isPurchase || refund) ? -amount.abs() : amount.abs(),
    kind: kind,
    method: invoice.paymentMethod ?? '',
    invoiceId: invoice.id,
    invoiceRef: invoice.reference,
    date: date,
    customerName: name,
    customerId: invoice.customerId ?? '',
    customerEmail: invoice.customerEmail ?? '',
    customerPhone: invoice.customerPhone ?? '',
    pdfUrl: invoice.pdfUrl,
    trackingUrl: invoice.trackingUrl,
    servedBy: invoice.servedBy,
    isPaid: (invoice.paymentStatus ?? '').toLowerCase() == 'paid',
    totalAmount: invoice.totalAmount,
    amountPaid: invoice.amountPaid,
    dueAmount: invoice.dueAmount,
    currencyCode: invoice.currency ?? '',
  );
}
