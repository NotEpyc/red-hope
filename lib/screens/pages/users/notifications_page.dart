import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../theme/theme.dart';
import '../../../models/notification.dart';
import '../../../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _setupNotificationsListener();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationsListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('time', descending: true);

    _notificationsSubscription = notificationsRef.snapshots().listen((snapshot) {
      if (!mounted) return;

      setState(() {
        _notifications = snapshot.docs.map((doc) => 
          NotificationModel.fromFirestore(doc.data(), doc.id)
        ).toList();
        _isLoading = false;
      });
    }, onError: (error) {
      debugPrint('Error fetching notifications: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final notificationsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications');

    for (var notification in _notifications.where((n) => !n.isRead)) {
      batch.update(notificationsRef.doc(notification.id), {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .doc(notification.id)
        .update({'isRead': true});
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case NotificationModel.chat:
        return Icons.chat_outlined;
      case NotificationModel.requestAccepted:
        return Icons.favorite_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case NotificationModel.chat:
        return Colors.blue[700]!;
      case NotificationModel.requestAccepted:
        return Colors.red[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    // Mark as read first
    await _markAsRead(notification);

    if (!mounted) return;

    // Navigate based on type
    if (notification.type == NotificationModel.chat) {
      // Navigate to chat with the sender
      final sender = notification.data?['sender'];
      if (sender != null) {
        Navigator.pushNamed(context, '/chat', arguments: sender);
      }
    } else if (notification.type == NotificationModel.requestAccepted) {
      // Navigate to donor profile
      final donor = notification.data?['donor'];
      if (donor != null) {
        Navigator.pushNamed(context, '/donor_profile', arguments: donor);
      }
    }
  }

  // Helper to create dummy notifications for testing
  Future<void> _createDummyNotifications() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await NotificationService.createDummyNotifications(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dummy notifications created!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating notifications: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          title: Text(
            'Notifications',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            // Debug button to create dummy notifications
            IconButton(
              icon: const Icon(Icons.bug_report_outlined, color: AppTheme.primaryColor),
              onPressed: _createDummyNotifications,
              tooltip: 'Create dummy notifications',
            ),
          ],
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Debug button to create dummy notifications
          IconButton(
            icon: const Icon(Icons.bug_report_outlined, color: AppTheme.primaryColor),
            onPressed: _createDummyNotifications,
            tooltip: 'Create dummy notifications',
          ),
          if (unreadCount > 0)
            TextButton.icon(
              icon: Icon(Icons.check_circle_outline, color: AppTheme.primaryColor),
              label: Text(
                'Mark all as read',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: notification.isRead
                        ? Colors.white
                        : AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(notification.type)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: _getNotificationColor(notification.type),
                        size: 24,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight:
                            notification.isRead ? FontWeight.w500 : FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTimeAgo(notification.time),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _handleNotificationTap(notification),
                  ),
                );
              },
            ),
    );
  }
}
