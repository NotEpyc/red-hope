import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  // Constants for notification types
  static const String chat = 'chat';
  static const String requestAccepted = 'request_accepted';
  final String id;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final String type;
  final Map<String, dynamic>? data; // Additional data like sender, donor etc.

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
    this.data,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> doc, String id) {
    return NotificationModel(
      id: id,
      title: doc['title'],
      message: doc['message'],
      time: (doc['time'] as Timestamp).toDate(),
      isRead: doc['isRead'] ?? false,
      type: doc['type'],
      data: doc['data'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'time': time,
      'isRead': isRead,
      'type': type,
      'data': data,
    };
  }
}
