import '../../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  final NotificationService _notificationService;

  NotificationRepository({NotificationService? notificationService})
      : _notificationService = notificationService ?? NotificationService();

  Future<NotificationModel?> getNotificationById(String notificationId) =>
      _notificationService.getNotificationById(notificationId);

  Future<void> saveNotification(NotificationModel notification) =>
      _notificationService.saveNotification(notification);

  Future<void> deleteNotification(String notificationId) => _notificationService.deleteNotification(notificationId);

  Future<List<NotificationModel>> getNotificationsList() => _notificationService.getNotificationsList();

  Stream<List<NotificationModel>> streamNotifications() => _notificationService.streamNotifications();
}
