import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_roles.dart';
import '../../../../providers/gallery_provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../models/gallery_item_model.dart';
import '../../home/widgets/glass_card.dart';
import 'components/add_gallery_item_dialog.dart';

class GalleryManagementView extends StatefulWidget {
  const GalleryManagementView({super.key});

  @override
  State<GalleryManagementView> createState() => _GalleryManagementViewState();
}

class _GalleryManagementViewState extends State<GalleryManagementView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _filterCategory = 'All';
  String _filterMediaType = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: GlassCard(
        backgroundOpacity: isDark ? 0.15 : 0.6,
        borderRadius: 14,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String val,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      value: val,
      isDense: true,
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(10),
      hint: Text(label),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoDialog(BuildContext context, String videoUrl, String title) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _VideoPlayerWidget(videoUrl: videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final Color secondaryColor = isDark ? AppColors.secondaryDark : AppColors.secondaryLight;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool canManageGallery =
        AppRoles.canManageGallery(auth.currentUser?.role);

    final galleryProvider = Provider.of<GalleryProvider>(context);
    List<GalleryItemModel> items = galleryProvider.galleryItems;

    // Filters
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      items = items.where((e) {
        return e.title.toLowerCase().contains(query) ||
            e.category.toLowerCase().contains(query) ||
            e.eventId.toLowerCase().contains(query);
      }).toList();
    }

    if (_filterCategory != 'All') {
      items = items.where((e) => e.category == _filterCategory).toList();
    }

    if (_filterMediaType != 'All') {
      items = items.where((e) => e.mediaType.toLowerCase() == _filterMediaType.toLowerCase()).toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        Row(
          children: [
            _buildSummaryCard('Total Photos', galleryProvider.totalPhotos.toString(), Icons.photo_library_rounded, Colors.blueAccent, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Total Videos', galleryProvider.totalVideos.toString(), Icons.video_library_rounded, Colors.purpleAccent, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Recent Uploads', galleryProvider.recentUploadsCount.toString(), Icons.upload_file_rounded, Colors.green, isDark),
            const SizedBox(width: 12),
            _buildSummaryCard('Event Galleries', galleryProvider.eventGalleriesCount.toString(), Icons.event_note_rounded, Colors.orange, isDark),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: secondaryColor,
                indicatorWeight: 3,
                dividerColor: Colors.transparent,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Grid View'),
                  Tab(text: 'List View'),
                ],
              ),
            ),
            if (canManageGallery)
              FloatingActionButton.extended(
                onPressed: () {
                  showDialog(context: context, builder: (_) => const AddGalleryItemDialog());
                },
                label: const Text('Upload Media'),
                icon: const Icon(Icons.upload_rounded),
                backgroundColor: secondaryColor,
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 2,
              ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Search & Filters Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SearchBar(
                controller: _searchController,
                hintText: 'Search by Title, Category, Event...',
                leading: const Icon(Icons.search_rounded),
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(
                  isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                ),
                onChanged: (val) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            _buildFilterDropdown(
              label: 'Category',
              val: _filterCategory,
              items: [
                'All', 'Cricket', 'Football', 'Basketball', 'Volleyball',
                'Athletics', 'Chess', 'Yoga', 'Sports Day', 'Tournament',
                'Achievement', 'Other'
              ],
              onChanged: (val) => setState(() => _filterCategory = val ?? 'All'),
            ),
            const SizedBox(width: 12),
            _buildFilterDropdown(
              label: 'Media Type',
              val: _filterMediaType,
              items: ['All', 'Image', 'Video'],
              onChanged: (val) => setState(() => _filterMediaType = val ?? 'All'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Grid View
              items.isEmpty
                  ? const Center(child: Text('No media found.'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return InkWell(
                          onTap: () {
                            if (item.mediaType == 'video') {
                              _showVideoDialog(context, item.videoUrl, item.title);
                            } else {
                              _showImageDialog(context, item.imageUrl, item.title);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                              image: item.mediaType == 'image' && item.imageUrl.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                if (item.mediaType == 'video')
                                  const Center(
                                    child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
                                  ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                                      color: Colors.black.withValues(alpha: 0.6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(item.category, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

              // List View
              items.isEmpty
                  ? const Center(child: Text('No media found.'))
                  : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 24,
                        headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                        columns: const [
                          DataColumn(label: Text('Preview', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: items.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    image: item.mediaType == 'image' && item.imageUrl.isNotEmpty
                                        ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: item.mediaType == 'video' ? Icon(Icons.play_circle_filled_rounded, color: primaryColor) : (item.imageUrl.isEmpty ? Icon(Icons.image_outlined, color: primaryColor) : null),
                                ),
                              ),
                              DataCell(Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(item.category)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: item.mediaType == 'video' ? Colors.purple.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item.mediaType.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: item.mediaType == 'video' ? Colors.purple : Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(DateFormat('MMM dd, yyyy').format(item.createdAt))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_rounded, size: 18, color: Colors.blueGrey),
                                      tooltip: 'View Media',
                                      onPressed: () {
                                        if (item.mediaType == 'video') {
                                          _showVideoDialog(context, item.videoUrl, item.title);
                                        } else {
                                          _showImageDialog(context, item.imageUrl, item.title);
                                        }
                                      },
                                    ),
                                    if (canManageGallery)
                                      IconButton(
                                        icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                                        tooltip: 'Delete Media',
                                        onPressed: () {
                                          galleryProvider.deleteGalleryItem(item.galleryId);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerWidget({required this.videoUrl});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          VideoProgressIndicator(_controller, allowScrubbing: true),
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: IconButton(
              icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white.withValues(alpha: 0.7), size: 64),
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
            ),
          )
        ],
      ),
    );
  }
}
