import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/event_model.dart';

class EventService {
  final FirebaseFirestore? _firestore;

  EventService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  // Fetch single event by ID
  Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await db.collection('events').doc(eventId).get();
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  // Save or update event
  Future<void> saveEvent(EventModel event) async {
    try {
      await db.collection('events').doc(event.eventId).set(event.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save event: $e');
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await db.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Fetch all events
  Future<List<EventModel>> getEventsList() async {
    try {
      final snapshot = await db.collection('events').orderBy('startDate', descending: false).get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events: $e');
    }
  }

  // Filter events by category
  Future<List<EventModel>> getEventsByCategory(String category) async {
    try {
      final snapshot = await db
          .collection('events')
          .where('category', isEqualTo: category)
          .orderBy('startDate', descending: false)
          .get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch events by category: $e');
    }
  }

  // Fetch upcoming events (date >= today)
  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final snapshot = await db
          .collection('events')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .orderBy('startDate', descending: false)
          .get();
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming events: $e');
    }
  }

  // Stream all events
  Stream<List<EventModel>> streamEvents() {
    return db.collection('events').orderBy('startDate', descending: false).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList();
    });
  }
}
