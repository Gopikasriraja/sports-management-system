import '../../models/gallery_item_model.dart';
import '../services/gallery_service.dart';

class GalleryRepository {
  final GalleryService _galleryService;

  GalleryRepository({GalleryService? galleryService}) : _galleryService = galleryService ?? GalleryService();

  Future<void> saveGalleryItem(GalleryItemModel item) => _galleryService.saveGalleryItem(item);

  Future<void> deleteGalleryItem(String galleryId) => _galleryService.deleteGalleryItem(galleryId);

  Future<List<GalleryItemModel>> getGalleryItemsList() => _galleryService.getGalleryItemsList();

  Future<List<GalleryItemModel>> getGalleryByCategory(String category) =>
      _galleryService.getGalleryByCategory(category);

  Stream<List<GalleryItemModel>> streamGalleryItems() => _galleryService.streamGalleryItems();
}
