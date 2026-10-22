import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryItemModel {
  final String galleryId;
  final String title;
  final String description;
  final String category;
  final String eventId;
  final String mediaType; // 'image' or 'video'
  final String imageUrl;
  final String videoUrl;
  final String uploadedBy;
  final DateTime createdAt;

  GalleryItemModel({
    required this.galleryId,
    required this.title,
    required this.description,
    required this.category,
    required this.eventId,
    required this.mediaType,
    required this.imageUrl,
    required this.videoUrl,
    required this.uploadedBy,
    required this.createdAt,
  });

  GalleryItemModel copyWith({
    String? galleryId,
    String? title,
    String? description,
    String? category,
    String? eventId,
    String? mediaType,
    String? imageUrl,
    String? videoUrl,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return GalleryItemModel(
      galleryId: galleryId ?? this.galleryId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      eventId: eventId ?? this.eventId,
      mediaType: mediaType ?? this.mediaType,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory GalleryItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GalleryItemModel.fromMap(data, doc.id);
  }

  factory GalleryItemModel.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return GalleryItemModel(
      galleryId: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      eventId: data['eventId'] ?? '',
      mediaType: data['mediaType'] ?? 'image',
      imageUrl: data['imageUrl'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'galleryId': galleryId,
      'title': title,
      'description': description,
      'category': category,
      'eventId': eventId,
      'mediaType': mediaType,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'uploadedBy': uploadedBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String toJson() => json.encode(toMap());

  factory GalleryItemModel.fromJson(String source, String id) =>
      GalleryItemModel.fromMap(json.decode(source) as Map<String, dynamic>, id);
}
