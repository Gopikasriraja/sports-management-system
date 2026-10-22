import 'dart:async';
import 'package:flutter/material.dart';
import '../database/repositories/gallery_repository.dart';
import '../models/gallery_item_model.dart';

class GalleryProvider extends ChangeNotifier {
  final GalleryRepository _galleryRepository;

  StreamSubscription? _gallerySub;

  GalleryProvider({
    GalleryRepository? galleryRepository,
    bool listenToRealtimeUpdates = true,
  })
      : _galleryRepository = galleryRepository ?? GalleryRepository() {
    if (listenToRealtimeUpdates) _initRealtimeListeners();
  }

  bool _isLoading = false;
  String? _errorMessage;
  List<GalleryItemModel> _galleryItems = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<GalleryItemModel> get galleryItems => _galleryItems;

  int get totalPhotos => _galleryItems.where((g) => g.mediaType == 'image').length;
  int get totalVideos => _galleryItems.where((g) => g.mediaType == 'video').length;
  int get recentUploadsCount {
    final now = DateTime.now();
    return _galleryItems.where((g) => now.difference(g.createdAt).inDays <= 7).length;
  }
  int get eventGalleriesCount => _galleryItems.map((g) => g.eventId).toSet().where((id) => id.isNotEmpty).length;

  @override
  void dispose() {
    _gallerySub?.cancel();
    super.dispose();
  }

  void _initRealtimeListeners() {
    _isLoading = true;
    _gallerySub = _galleryRepository.streamGalleryItems().listen((list) {
      _galleryItems = list;
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

  Future<void> fetchGalleryItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _galleryItems = await _galleryRepository.getGalleryItemsList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGalleryByCategory(String category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _galleryItems = await _galleryRepository.getGalleryByCategory(category);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveGalleryItem(GalleryItemModel item) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _galleryRepository.saveGalleryItem(item);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteGalleryItem(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _galleryRepository.deleteGalleryItem(id);
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
