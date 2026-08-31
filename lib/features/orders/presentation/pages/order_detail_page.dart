import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../profile/presentation/controller/profile_controller.dart';
import '../../../repair/presentation/controller/repair_data.dart';
import '../../../repair/presentation/widgets/timeline_widget.dart';
import '../../domain/entities/order_ready_item.dart';

/// Shows where an order sits in the repair → ready-for-collection → charged
/// pipeline. The repair stages are reused from the repair feature's
/// timeline; the two stages after "Repair Complete" belong to Orders.
class OrderDetailPage extends StatelessWidget {
  final OrderReadyItem order;

  const OrderDetailPage({super.key, required this.order});

  String get _currencySymbol => Get.find<ProfileController>().currencySymbol;

  List<TimelineStep> get _steps => [
    TimelineStep(
      'Order Booked',
      'Order was created for this repair',
      TimelineStatus.done,
    ),
    TimelineStep(
      'Order Assigned',
      'A technician was assigned',
      TimelineStatus.done,
    ),
    TimelineStep(
      'Repairing Started',
      'Device was repaired',
      TimelineStatus.done,
    ),
    TimelineStep(
      'Repair Complete',
      'Repair finished and quality-checked',
      TimelineStatus.done,
    ),
    TimelineStep(
      'Ready for Collection',
      'Waiting for the customer to collect and pay',
      TimelineStatus.inProgress,
    ),
    TimelineStep(
      'Collected & Paid',
      'Order handed over and payment received',
      TimelineStatus.pending,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          const AppHeader(title: 'Order Details'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                TimelineWidget(steps: _steps),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppButton(
              label: 'Charge $_currencySymbol${order.price.toStringAsFixed(2)}',
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: Text(
                  order.initials,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.itemDescription,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$_currencySymbol${order.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            order.readySince,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
