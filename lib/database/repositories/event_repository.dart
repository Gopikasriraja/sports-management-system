import '../../models/event_model.dart';
import '../services/event_service.dart';

class EventRepository {
  final EventService _eventService;

  EventRepository({EventService? eventService}) : _eventService = eventService ?? EventService();

  Future<EventModel?> getEventById(String eventId) => _eventService.getEventById(eventId);

  Future<void> saveEvent(EventModel event) => _eventService.saveEvent(event);

  Future<void> deleteEvent(String eventId) => _eventService.deleteEvent(eventId);

  Future<List<EventModel>> getEventsList() => _eventService.getEventsList();

  Future<List<EventModel>> getEventsByCategory(String category) =>
      _eventService.getEventsByCategory(category);

  Future<List<EventModel>> getUpcomingEvents() => _eventService.getUpcomingEvents();

  Stream<List<EventModel>> streamEvents() => _eventService.streamEvents();
}
