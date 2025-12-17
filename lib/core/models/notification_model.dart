import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { push, inApp }
enum NotificationCategory { booking, payment, reminder, system }

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationCategory category;
  final String title;
  final String message;
  final bool read;
  final DateTime sentAt;
  final String? bookingId;
  final String? carId;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    this.read = false,
    required this.sentAt,
    this.bookingId,
    this.carId,
    this.metadata,
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
        orElse: () => NotificationType.inApp,
      ),
      category: NotificationCategory.values.firstWhere(
        (e) => e.toString() == 'NotificationCategory.${map['category']}',
        orElse: () => NotificationCategory.system,
      ),
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      read: map['read'] ?? false,
      sentAt: (map['sentAt'] as Timestamp).toDate(),
      bookingId: map['bookingId'],
      carId: map['carId'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'title': title,
      'message': message,
      'read': read,
      'sentAt': Timestamp.fromDate(sentAt),
      'bookingId': bookingId,
      'carId': carId,
      'metadata': metadata,
    };
  }

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: type,
      category: category,
      title: title,
      message: message,
      read: read ?? this.read,
      sentAt: sentAt,
      bookingId: bookingId,
      carId: carId,
      metadata: metadata,
    );
  }
}
