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
    price: (item['price'] as num?)?.toDouble() ?? 0,
    createdAt: createdAt,
    raw: item,
  );
}

String formatRepairStatus(String? status) {
  return switch (status) {
    'completed' => 'Completed',
    'inProgress' ||
    'quote_sent' ||
    'approved' ||
    'inReview' ||
    'start-work' ||
    'waiting-for-parts' ||
    'order-assigned' ||
    'diagnosing' ||
    'repairing' => 'In Progress',
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
