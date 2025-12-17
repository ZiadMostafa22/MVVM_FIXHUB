import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/core/models/notification_model.dart';
import 'package:car_maintenance_system_new/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:timeago/timeago.dart' as timeago;

// Simple provider for unread count
final unreadCountProvider = StreamProvider.autoDispose<int>((ref) {
  final authState = ref.watch(authViewModelProvider);
  final userId = authState.userId;
  
  if (userId == null) {
    return Stream.value(0);
  }
  
  // Simple query - just get all notifications for user and count unread in memory
  return FirebaseFirestore.instance
      .collection('user_notifications')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        int count = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          if (data['read'] != true) {
            count++;
          }
        }
        return count;
      });
});

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authState = ref.read(authViewModelProvider);
    final userId = authState.userId;
    
    if (userId == null) {
      setState(() {
        _error = 'User not logged in';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Simple query without composite index
      final snapshot = await _firestore
          .collection('user_notifications')
          .where('userId', isEqualTo: userId)
          .get();

      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Sort by sentAt in memory
      notifications.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      setState(() {
        _notifications = notifications.take(50).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('user_notifications')
          .doc(notificationId)
          .update({'read': true});
      
      // Update local state
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          _notifications[index] = NotificationModel(
            id: notification.id,
            userId: notification.userId,
            type: notification.type,
            category: notification.category,
            title: notification.title,
            message: notification.message,
            read: true,
            sentAt: notification.sentAt,
            bookingId: notification.bookingId,
            carId: notification.carId,
            metadata: notification.metadata,
          );
        }
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final authState = ref.read(authViewModelProvider);
    final userId = authState.userId;
    
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      
      for (var notification in _notifications.where((n) => !n.read)) {
        batch.update(
          _firestore.collection('user_notifications').doc(notification.id),
          {'read': true},
        );
      }
      
      await batch.commit();
      
      // Reload to refresh UI
      await _loadNotifications();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('user_notifications')
          .doc(notificationId)
          .delete();
      
      setState(() {
        _notifications.removeWhere((n) => n.id == notificationId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                      SizedBox(height: 16.h),
                      Text('Error: $_error'),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: _loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64.sp, color: Colors.grey),
                          SizedBox(height: 16.h),
                          Text(
                            'No notifications yet',
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: EdgeInsets.all(8.w),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
      elevation: notification.read ? 0 : 2,
      color: notification.read ? null : Theme.of(context).primaryColor.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(notification.category).withOpacity(0.2),
          child: Icon(
            _getCategoryIcon(notification.category),
            color: _getCategoryColor(notification.category),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
            fontSize: 14.sp,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              notification.message,
              style: TextStyle(fontSize: 12.sp),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4.h),
            Text(
              timeago.format(notification.sentAt),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'mark_read':
                _markAsRead(notification.id);
                break;
              case 'delete':
                _deleteNotification(notification.id);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!notification.read)
              const PopupMenuItem(
                value: 'mark_read',
                child: Text('Mark as read'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
        onTap: () {
          if (!notification.read) {
            _markAsRead(notification.id);
          }
        },
        isThreeLine: true,
      ),
    );
  }

  IconData _getCategoryIcon(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.booking:
        return Icons.calendar_today;
      case NotificationCategory.payment:
        return Icons.payment;
      case NotificationCategory.reminder:
        return Icons.alarm;
      case NotificationCategory.system:
        return Icons.info;
    }
  }

  Color _getCategoryColor(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.booking:
        return Colors.blue;
      case NotificationCategory.payment:
        return Colors.green;
      case NotificationCategory.reminder:
        return Colors.orange;
      case NotificationCategory.system:
        return Colors.purple;
    }
  }
}
