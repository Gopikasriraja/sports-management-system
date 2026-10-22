import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore? _firestore;

  NotificationService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  // Fetch single notification by ID
  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final doc = await db.collection('notifications').doc(notificationId).get();
      if (doc.exists) {
        return NotificationModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch notification: $e');
    }
  }

  // Save announcement
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      await db
          .collection('notifications')
          .doc(notification.notificationId)
          .set(notification.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save notification: $e');
    }
  }

  // Delete announcement
  Future<void> deleteNotification(String notificationId) async {
    try {
      await db.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Fetch announcements
  Future<List<NotificationModel>> getNotificationsList() async {
    try {
      final snapshot = await db.collection('notifications').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Stream announcements
  Stream<List<NotificationModel>> streamNotifications() {
    return db.collection('notifications').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
    });
  }
}
