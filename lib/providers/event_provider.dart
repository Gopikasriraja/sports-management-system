import 'dart:async';
import 'package:flutter/material.dart';
import '../database/repositories/event_repository.dart';
import '../models/event_model.dart';

class EventProvider extends ChangeNotifier {
  final EventRepository _eventRepository;

  StreamSubscription? _eventsSub;

  EventProvider({
    EventRepository? eventRepository,
    bool listenToRealtimeUpdates = true,
  }) : _eventRepository = eventRepository ?? EventRepository() {
    if (listenToRealtimeUpdates) _initRealtimeListeners();
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<EventModel> _events = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EventModel> get events => _events;

  // Dashboard Metrics
  int get totalEvents => _events.length;
  int get upcomingEventsCount => _events.where((e) => e.status.toLowerCase() == 'upcoming').length;
  int get ongoingEventsCount => _events.where((e) => e.status.toLowerCase() == 'ongoing').length;
  int get completedEventsCount => _events.where((e) => e.status.toLowerCase() == 'completed').length;
  int get thisMonthEventsCount {
    final now = DateTime.now();
    return _events.where((e) => e.startDate.year == now.year && e.startDate.month == now.month).length;
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  void _initRealtimeListeners() {
    _isLoading = true;
    _eventsSub = _eventRepository.streamEvents().listen((list) {
      _events = list;
      _isLoading = false;
      notifyListeners();
    }, onError: (err) {
      _errorMessage = err.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventRepository.getEventsList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveEvent(EventModel event) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventRepository.saveEvent(event);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEvent(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _eventRepository.deleteEvent(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEventsByCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventRepository.getEventsByCategory(category);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventRepository.getUpcomingEvents();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
