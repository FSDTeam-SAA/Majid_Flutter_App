import '../controller/repair_data.dart';

RepairItem repairItemFromJson(Map<String, dynamic> item) {
  final createdAt = DateTime.tryParse(
    item['createdAt']?.toString() ?? '',
  )?.toLocal();

  return RepairItem(
    name: item['firstName']?.toString() ?? 'Customer',
    brand: item['deviceModel']?.toString() ?? 'Unknown device',
    issueLabel: 'Issue Summary',
    issueDesc: item['description']?.toString() ?? 'No description provided',
    date: formatRepairDate(item['createdAt']?.toString()),
    status: formatRepairStatus(item['status']?.toString()),
    rawStatus: item['status']?.toString() ?? '',
    price: (item['price'] as num?)?.toDouble() ?? 0,
    createdAt: createdAt,
    raw: item,
  );
}

String formatRepairStatus(String? status) {
  return switch (status) {
    'completed' => 'Completed',
    'collected' => 'Collected',
    'unable-to-repair' => 'Unable to Repair',
    'waiting-for-parts' => 'Waiting for Parts',
    'quote_sent' || 'quote-sent' => 'Quote Sent',
    'approved' => 'Approved',
    'inReview' => 'In Review',
    'start-work' => 'Start Work',
    'order-assigned' => 'Order Assigned',
    'diagnosing' => 'Diagnosing',
    'repairing' => 'Repairing',
    'reassigned' => 'Reassigned',
    'inProgress' => 'In Progress',
    'rejected' => 'Rejected',
    _ => status ?? 'In Progress',
  };
}

String formatRepairDate(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) return '';

  final local = parsed.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[local.month - 1]} ${local.day.toString().padLeft(2, '0')}, ${local.year}';
}

/// Include identifiers and customer contacts, not only the card's display label.
bool repairMatchesQuery(RepairItem item, String query) => [
  item.name,
  item.brand,
  item.imei,
  item.issueDesc,
  item.status,
  item.raw['_id'],
  item.raw['email'],
  item.raw['phoneNumber'],
].join(' ').toLowerCase().contains(query.trim().toLowerCase());
