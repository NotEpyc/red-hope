import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a chat notification to a user
  static Future<void> sendChatNotification({
    required String userId,
    required String senderName,
    required String message,
  }) async {
    final notification = NotificationModel(
      id: '', // Will be set by Firestore
      title: senderName,
      message: message,
      time: DateTime.now(),
      type: NotificationModel.chat,
      data: {'sender': senderName},
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification.toFirestore());
  }

  // Send a notification when a donor accepts to donate blood
  static Future<void> sendDonationAcceptedNotification({
    required String userId,
    required String donorName,
    String? requestId,
  }) async {
    final notification = NotificationModel(
      id: '', // Will be set by Firestore
      title: 'Blood Request Accepted',
      message: '$donorName is willing to donate blood for your request',
      time: DateTime.now(),
      type: NotificationModel.requestAccepted,
      data: {
        'donor': donorName,
        if (requestId != null) 'requestId': requestId,
      },
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add(notification.toFirestore());
  }

  // Get unread notification count for a user
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Create dummy notifications for testing
  static Future<void> createDummyNotifications(String userId) async {
    final batch = _firestore.batch();
    final notificationsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');

    // Chat notification - unread
    final chatNotification = NotificationModel(
      id: '',
      title: 'Dr. Sarah',
      message: 'Can you come to City Hospital today?',
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      type: NotificationModel.chat,
      data: {'sender': 'Dr. Sarah'},
    );

    // Blood request accepted - unread
    final requestAcceptedNotification = NotificationModel(
      id: '',
      title: 'Blood Request Accepted',
      message: 'John Smith is willing to donate blood for your request',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationModel.requestAccepted,
      data: {
        'donor': 'John Smith',
        'requestId': 'req123',
      },
    );

    // Old chat notification - read
    final oldChatNotification = NotificationModel(
      id: '',
      title: 'Blood Bank',
      message: 'Your last donation was successful',
      time: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationModel.chat,
      isRead: true,
      data: {'sender': 'Blood Bank'},
    );

    // Old request notification - read
    final oldRequestNotification = NotificationModel(
      id: '',
      title: 'Blood Request Accepted',
      message: 'Mary Johnson is willing to donate blood for your request',
      time: DateTime.now().subtract(const Duration(days: 2)),
      type: NotificationModel.requestAccepted,
      isRead: true,
      data: {
        'donor': 'Mary Johnson',
        'requestId': 'req120',
      },
    );

    // Add all notifications to batch
    final notifications = [
      chatNotification,
      requestAcceptedNotification,
      oldChatNotification,
      oldRequestNotification,
    ];

    // Delete existing notifications first
    final existingDocs = await notificationsRef.get();
    for (var doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }

    // Add new notifications
    for (var notification in notifications) {
      final docRef = notificationsRef.doc();
      batch.set(docRef, notification.toFirestore());
    }

    await batch.commit();
  }
}
