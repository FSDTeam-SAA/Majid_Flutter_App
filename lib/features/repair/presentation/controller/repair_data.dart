class RepairItem {
  final String name;
  final String brand;
  final String issueLabel;
  final String issueDesc;
  final String date;
  final String status;

  RepairItem({
    required this.name,
    required this.brand,
    required this.issueLabel,
    required this.issueDesc,
    required this.date,
    required this.status,
  });
}

List<RepairItem> sampleRepairs = [
  RepairItem(
    name: 'Muhammad Majid',
    brand: 'Realme',
    issueLabel: 'Issue Summary',
    issueDesc: 'iPad front touch broken, Apple logo blinking.',
    date: 'Jun 04, 2026',
    status: 'Completed',
  ),
  RepairItem(
    name: 'Sarah Johnson',
    brand: 'Samsung',
    issueLabel: 'Performance Lag',
    issueDesc: 'Device frequently freezes during use.',
    date: 'Jun 05, 2026',
    status: 'In Progress',
  ),
  RepairItem(
    name: 'David Lee',
    brand: 'Google',
    issueLabel: 'Battery Issue',
    issueDesc: 'Battery drains rapidly even when idle.',
    date: 'Jun 06, 2026',
    status: 'In Progress',
  ),
];

enum TimelineStatus { done, inProgress, pending }

class TimelineStep {
  final String title;
  final String subtitle;
  final TimelineStatus status;
  TimelineStep(this.title, this.subtitle, this.status);
}

List<TimelineStep> repairTimeline = [
  TimelineStep(
    'Order Booked',
    'Your order has been successfully created',
    TimelineStatus.done,
  ),
  TimelineStep(
    'Order Assigned',
    'A technician has been assigned',
    TimelineStatus.inProgress,
  ),
  TimelineStep(
    'Diagnosing Started',
    'Technician is diagnosing the issue',
    TimelineStatus.pending,
  ),
  TimelineStep(
    'Quote Sent',
    'A quote has been sent for the repair',
    TimelineStatus.pending,
  ),
  TimelineStep(
    'Repairing Started',
    'Device is being repaired',
    TimelineStatus.pending,
  ),
  TimelineStep(
    'Waiting for Parts',
    'Repair is paused until parts arrive',
    TimelineStatus.pending,
  ),
  TimelineStep(
    'Repair Complete',
    'Repair has been successfully completed',
    TimelineStatus.pending,
  ),
  TimelineStep(
    'Checkout',
    'Repair has been successfully completed',
    TimelineStatus.pending,
  ),
];

class CheckoutProduct {
  final String name;
  final String code;
  final double price;
  final int colorHex;
  CheckoutProduct({
    required this.name,
    required this.code,
    required this.price,
    required this.colorHex,
  });
}

List<CheckoutProduct> checkoutProducts = [
  CheckoutProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    colorHex: 0xFF2C2C2E,
  ),
  CheckoutProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    colorHex: 0xFFFF6B9D,
  ),
  CheckoutProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    colorHex: 0xFF5B8DEF,
  ),
  CheckoutProduct(
    name: 'iPhone 14 Pro',
    code: 'PRD-1001',
    price: 899.00,
    colorHex: 0xFFE0E0E0,
  ),
];
