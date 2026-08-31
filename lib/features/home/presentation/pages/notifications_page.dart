import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/api_service/api_client.dart';
import '../../../../core/network/api_service/api_endpoints.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/gradient_scaffold.dart';
import '../../../../core/widgets/more_menu_button.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final ApiClient _api;
  var _isLoading = true;
  var _errorMessage = '';
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final res = await _api.get(NotificationEndpoints.shopkeeper);
      final data = res.data['data'];
      if (data is! List) {
        throw const FormatException('Invalid notifications response');
      }
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(data);
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
            e.response?.data?['message'] ?? 'Failed to load notifications';
      });
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(Map<String, dynamic> item) async {
    final id = item['_id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      await _api.patch(NotificationEndpoints.read(id));
      if (!mounted) return;
      setState(() => item['isViewed'] = true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update notification.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: Column(
        children: [
          AppHeader(title: 'Notifications', trailing: MoreMenuButton()),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _fetchNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBackground,
      onRefresh: _fetchNotifications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length,
        separatorBuilder: (_, _) =>
            Divider(color: AppColors.fieldBorder, height: 1, thickness: 1),
        itemBuilder: (context, index) =>
            _buildNotifItem(context, _notifications[index]),
      ),
    );
  }

  Widget _buildNotifItem(BuildContext context, Map<String, dynamic> item) {
    final title =
        item['title']?.toString() ?? item['type']?.toString() ?? 'Notification';
    final desc =
        item['message']?.toString() ??
        item['description']?.toString() ??
        item['body']?.toString() ??
        '';
    final time = _formatTime(item['createdAt']?.toString());
    final isUnread = item['isViewed'] != true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (isUnread) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => _markAsRead(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Read',
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

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final now = DateTime.now();
    final local = parsed.toLocal();
    final diff = now.difference(local);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
