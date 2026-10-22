import 'dart:async';
import 'package:flutter/material.dart';
import '../database/repositories/notification_repository.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository;
  StreamSubscription? _notificationSub;

  NotificationProvider({
    NotificationRepository? notificationRepository,
    bool listenToRealtimeUpdates = true,
  })
      : _notificationRepository = notificationRepository ?? NotificationRepository() {
    if (listenToRealtimeUpdates) _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    _isLoading = true;
    _notificationSub = _notificationRepository.streamNotifications().listen((list) {
      _notifications = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => _notifications;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _notificationRepository.getNotificationsList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveNotification(NotificationModel notification) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notificationRepository.saveNotification(notification);
      await fetchNotifications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteNotification(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notificationRepository.deleteNotification(id);
      await fetchNotifications();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
