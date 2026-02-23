import 'package:flutter/material.dart';
import '../../app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Notification> _notifications = [
    Notification(
      id: 1,
      title: 'Temperature Alert',
      message: 'Temperature exceeded safe threshold in Greenhouse A',
      type: AlertType.danger,
      channel: 'SMS',
      timestamp: 'Today, 2:30 PM',
      isRead: false,
    ),
    Notification(
      id: 2,
      title: 'Humidity Low',
      message: 'Humidity dropped below minimum level',
      type: AlertType.warning,
      channel: 'Email',
      timestamp: 'Today, 1:15 PM',
      isRead: false,
    ),
    Notification(
      id: 3,
      title: 'System Check Complete',
      message: 'Regular system health check completed successfully',
      type: AlertType.info,
      channel: 'In-App',
      timestamp: 'Today, 10:00 AM',
      isRead: true,
    ),
    Notification(
      id: 4,
      title: 'Feeding Schedule Updated',
      message: 'New feeding schedule has been applied to Colony A',
      type: AlertType.success,
      channel: 'In-App',
      timestamp: 'Yesterday, 5:45 PM',
      isRead: true,
    ),
    Notification(
      id: 5,
      title: 'Worker Added',
      message: 'Sarah Smith has been added as a Technician',
      type: AlertType.info,
      channel: 'Email',
      timestamp: 'Yesterday, 3:20 PM',
      isRead: true,
    ),
    Notification(
      id: 6,
      title: 'Air Quality Alert',
      message: 'Air quality index exceeded acceptable range',
      type: AlertType.danger,
      channel: 'SMS',
      timestamp: 'Feb 20, 8:15 AM',
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Notifications'),
        elevation: 0.5,
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '$unreadCount new',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter/Sort Options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _FilterChip(label: 'All', isActive: true),
                  _FilterChip(label: 'Unread', isActive: false),
                  _FilterChip(label: 'Alerts', isActive: false),
                  _FilterChip(label: 'SMS', isActive: false),
                ],
              ),
            ),

            // Notifications List
            ..._notifications.map((notification) {
              return _NotificationItem(
                notification: notification,
                onTap: () => _markAsRead(notification.id),
                onDelete: () => _deleteNotification(notification.id),
              );
            }).toList(),

            if (_notifications.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 60, horizontal: 16),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: AppColors.textHint),
                    SizedBox(height: 16),
                    Text(
                      'No notifications yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You\'re all caught up!',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _markAsRead(int id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = Notification(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          channel: _notifications[index].channel,
          timestamp: _notifications[index].timestamp,
          isRead: true,
        );
      }
    });
  }

  void _deleteNotification(int id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
  }
}

enum AlertType { danger, warning, success, info }

class Notification {
  final int id;
  final String title;
  final String message;
  final AlertType type;
  final String channel;
  final String timestamp;
  final bool isRead;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.channel,
    required this.timestamp,
    required this.isRead,
  });
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _FilterChip({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (value) {},
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isActive ? AppColors.primary : AppColors.textHint,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isActive ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Notification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  Color _getTypeColor() {
    switch (notification.type) {
      case AlertType.danger:
        return AppColors.error;
      case AlertType.warning:
        return AppColors.warning;
      case AlertType.success:
        return AppColors.success;
      case AlertType.info:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case AlertType.danger:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_outlined;
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.info:
        return Icons.info_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id.toString()),
      onDismissed: (direction) => onDelete(),
      child: Container(
        color: notification.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _getTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTypeIcon(),
                      color: _getTypeColor(),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                                    ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          notification.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              notification.timestamp,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                notification.channel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Delete Button
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: AppColors.textHint),
                    onPressed: onDelete,
                    constraints: BoxConstraints(),
                    padding: EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
