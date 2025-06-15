import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../theme/theme.dart';
import '../../../models/notification.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
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
        .collection('organisations')
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
        .collection('organisations')
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
        .collection('organisations')
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
      case 'request':
        return Icons.local_hospital_outlined;
      case 'donation':
        return Icons.favorite_outline;
      case 'donor':
        return Icons.person_outline;
      case NotificationModel.chat:
        return Icons.chat_outlined;
      case NotificationModel.requestAccepted:
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'request':
        return Colors.orange;
      case 'donation':
        return Colors.red;
      case 'donor':
        return Colors.blue;
      case NotificationModel.chat:
        return Colors.teal;
      case NotificationModel.requestAccepted:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        title: Text(
          'Notifications',            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
            ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark all as read',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SpinKitPumpingHeart(
                color: AppTheme.primaryColor,
                size: 80.0,
                controller: AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
              )
            )
          : _notifications.isEmpty
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
                        'No notifications yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: notification.isRead ? 1 : 2,
                      color: notification.isRead
                          ? Colors.white
                          : AppTheme.primaryColor.withOpacity(0.05),
                      child: InkWell(
                        onTap: () async {
                          await _markAsRead(notification);
                          // Implement navigation based on notification type
                        },
                        borderRadius: BorderRadius.circular(15),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getNotificationColor(notification.type)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getNotificationIcon(notification.type),
                                  color: _getNotificationColor(notification.type),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontWeight:
                                            notification.isRead ? FontWeight.normal : FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification.message,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getTimeAgo(notification.time),
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
