import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String title;
  final String category;
  final String eventType;
  final DateTime startDate;
  final DateTime endDate;
  final String startTime;
  final String endTime;
  final String venue;
  final String organizer;
  final String department;
  final String description;
  final int maxParticipants;
  final bool registrationRequired;
  final String bannerImage;
  final String status;

  EventModel({
    required this.eventId,
    required this.title,
    required this.category,
    required this.eventType,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.organizer,
    required this.department,
    required this.description,
    required this.maxParticipants,
    required this.registrationRequired,
    required this.bannerImage,
    required this.status,
  });

  EventModel copyWith({
    String? eventId,
    String? title,
    String? category,
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? venue,
    String? organizer,
    String? department,
    String? description,
    int? maxParticipants,
    bool? registrationRequired,
    String? bannerImage,
    String? status,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      category: category ?? this.category,
      eventType: eventType ?? this.eventType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
      organizer: organizer ?? this.organizer,
      department: department ?? this.department,
      description: description ?? this.description,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registrationRequired: registrationRequired ?? this.registrationRequired,
      bannerImage: bannerImage ?? this.bannerImage,
      status: status ?? this.status,
    );
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EventModel.fromMap(data, doc.id);
  }

  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return EventModel(
      eventId: id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      eventType: data['eventType'] ?? 'General',
      startDate: parseDate(data['startDate'] ?? data['date']),
      endDate: parseDate(data['endDate'] ?? data['date']),
      startTime: data['startTime'] ?? data['time'] ?? '',
      endTime: data['endTime'] ?? '',
      venue: data['venue'] ?? '',
      organizer: data['organizer'] ?? 'Admin',
      department: data['department'] ?? 'All',
      description: data['description'] ?? '',
      maxParticipants: data['maxParticipants'] ?? 0,
      registrationRequired: data['registrationRequired'] ?? false,
      bannerImage: data['bannerImage'] ?? '',
      status: data['status'] ?? 'Upcoming',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'title': title,
      'category': category,
      'eventType': eventType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'startTime': startTime,
      'endTime': endTime,
      'venue': venue,
      'organizer': organizer,
      'department': department,
      'description': description,
      'maxParticipants': maxParticipants,
      'registrationRequired': registrationRequired,
      'bannerImage': bannerImage,
      'status': status,
    };
  }

  String toJson() => json.encode(toMap());

  factory EventModel.fromJson(String source, String id) =>
      EventModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}
