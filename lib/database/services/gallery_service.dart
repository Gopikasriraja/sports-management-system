import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/gallery_item_model.dart';

class GalleryService {
  final FirebaseFirestore? _firestore;

  GalleryService({FirebaseFirestore? db}) : _firestore = db;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  // Save gallery item
  Future<void> saveGalleryItem(GalleryItemModel item) async {
    try {
      await db.collection('gallery').doc(item.galleryId).set(item.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save gallery item: $e');
    }
  }

  // Delete gallery item
  Future<void> deleteGalleryItem(String galleryId) async {
    try {
      await db.collection('gallery').doc(galleryId).delete();
    } catch (e) {
      throw Exception('Failed to delete gallery item: $e');
    }
  }

  // Fetch gallery list
  Future<List<GalleryItemModel>> getGalleryItemsList() async {
    try {
      final snapshot = await db.collection('gallery').orderBy('createdAt', descending: true).get();
      return snapshot.docs.map((doc) => GalleryItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch gallery: $e');
    }
  }

  // Filter gallery by category
  Future<List<GalleryItemModel>> getGalleryByCategory(String category) async {
    try {
      final snapshot = await db
          .collection('gallery')
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => GalleryItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch gallery by category: $e');
    }
  }

  // Stream gallery
  Stream<List<GalleryItemModel>> streamGalleryItems() {
    return db.collection('gallery').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => GalleryItemModel.fromFirestore(doc)).toList();
    });
  }
}
