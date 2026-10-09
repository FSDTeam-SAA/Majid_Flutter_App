import '../controller/repair_data.dart';

List<TimelineStep> buildRepairTimeline(String status) {
  // Reassignment and waiting are branches, not milestones every repair passed.
  final phases = <(String, String, String)>[
    ('inProgress', 'Order Booked', 'Your order has been successfully created'),
    ('order-assigned', 'Order Assigned', 'A technician has been assigned'),
    if (status == 'reassigned')
      ('reassigned', 'Reassigned', 'The repair has been reassigned'),
    ('diagnosing', 'Diagnosing Started', 'Technician is diagnosing the issue'),
    ('quote_sent', 'Quote Sent', 'A quote has been sent for the repair'),
    ('repairing', 'Repairing Started', 'Device is being repaired'),
    if (status == 'waiting-for-parts')
      (
        'waiting-for-parts',
        'Waiting for Parts',
        'Repair is paused until parts arrive',
      ),
    ('completed', 'Repair Complete', 'Repair has been successfully completed'),
  ];
  final canonical = switch (status) {
    'approved' || 'quote-sent' => 'quote_sent',
    'start-work' => 'repairing',
    'inReview' => 'diagnosing',
    'collected' => 'completed',
    _ => status,
  };
  final current = phases.indexWhere((phase) => phase.$1 == canonical);
  final finished = {
    'completed',
    'collected',
    'order-assigned',
    'quote_sent',
    'quote-sent',
    'approved',
    'reassigned',
    'inProgress',
  }.contains(status);
  return phases.indexed
      .map(
        (entry) => TimelineStep(
          entry.$2.$2,
          entry.$2.$3,
          current < 0 || entry.$1 > current
              ? TimelineStatus.pending
              : entry.$1 < current || finished
              ? TimelineStatus.done
              : TimelineStatus.inProgress,
        ),
      )
      .toList();
}
