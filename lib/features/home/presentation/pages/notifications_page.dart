import 'package:flutter/material.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/user_avatar.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const _notifications = [
    _NotifItem(
      title: 'New inquiry from Sarah Jenkins',
      desc:
          '"Hello, I\'m interested in the premium bulk package. Do you offer seasonal discounts fo......"',
      time: 'Today',
      hasView: true,
    ),
    _NotifItem(
      title: 'Flash Sale Campaign Active',
      desc:
          '"Your \'Summer Breeze\' campaign has reached 500+ impressions in the last hour. Conversion..."',
      time: 'Today',
      hasView: true,
    ),
    _NotifItem(
      title: 'Invoice #88293 Paid',
      desc:
          'Payment for \$1,240.00 from Global Logistics Co. has been processed and added to your balance.',
      time: 'Yesterday',
      hasView: false,
    ),
    _NotifItem(
      title: 'Feedback Received',
      desc:
          'A customer left a 5-star review on \'Ergonomic Desk Chair\': "Fast shipping and amazing quality!"',
      time: 'Yesterday',
      hasView: false,
    ),
    _NotifItem(
      title: 'New inquiry from Sarah Jenkins',
      desc:
          '"Hello, I\'m interested in the premium bulk package. Do you offer seasonal discounts for long-term partners?"',
      time: 'Today',
      hasView: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Notifications', trailing: UserAvatar()),
          Expanded(
            child: ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (_, _) =>
                  Divider(color: AppColors.fieldBorder, height: 1, thickness: 1),
              itemBuilder: (context, index) =>
                  _buildNotifItem(context, _notifications[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifItem(BuildContext context, _NotifItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  item.desc,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.time,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (item.hasView) ...[
                SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(item.title)));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NotifItem {
  final String title;
  final String desc;
  final String time;
  final bool hasView;
  const _NotifItem({
    required this.title,
    required this.desc,
    required this.time,
    required this.hasView,
  });
}
