import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/gallery_item_model.dart';
import '../../../providers/gallery_provider.dart';

class MediaGallery extends StatefulWidget {
  const MediaGallery({super.key});

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  String _selectedTab = 'Photos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().fetchGalleryItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<GalleryProvider>();
    final isPhotos = _selectedTab == 'Photos';
    final items = provider.galleryItems
        .where(
          (item) => isPhotos
              ? item.mediaType.toLowerCase() == 'image'
              : item.mediaType.toLowerCase() == 'video',
        )
        .toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    final width = MediaQuery.of(context).size.width;
    final columns = width < 600 ? 1 : (width < 960 ? 2 : 3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sports Gallery', style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          'Media shown here comes from the gallery records.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Photos'),
              selected: isPhotos,
              onSelected: (_) => setState(() => _selectedTab = 'Photos'),
            ),
            ChoiceChip(
              label: const Text('Videos'),
              selected: !isPhotos,
              onSelected: (_) => setState(() => _selectedTab = 'Videos'),
            ),
            if (provider.errorMessage != null)
              ActionChip(
                avatar: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                onPressed: provider.fetchGalleryItems,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (provider.isLoading && provider.galleryItems.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: CircularProgressIndicator(),
            ),
          )
        else if (provider.errorMessage != null &&
            provider.galleryItems.isEmpty)
          const _GalleryStatus(
            icon: Icons.cloud_off_outlined,
            message: 'Gallery items could not be loaded.',
          )
        else if (items.isEmpty)
          _GalleryStatus(
            icon: isPhotos
                ? Icons.photo_library_outlined
                : Icons.video_library_outlined,
            message: isPhotos
                ? 'There are no photos in the gallery yet.'
                : 'There are no videos in the gallery yet.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) =>
                _GalleryCard(item: items[index]),
          ),
      ],
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final GalleryItemModel item;

  const _GalleryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = item.mediaType.toLowerCase() == 'video';
    final imageUrl = isVideo ? item.videoUrl : item.imageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: imageUrl.isEmpty
                ? ColoredBox(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      isVideo
                          ? Icons.play_circle_outline_rounded
                          : Icons.image_not_supported_outlined,
                      size: 42,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        isVideo
                            ? Icons.play_circle_outline_rounded
                            : Icons.broken_image_outlined,
                        size: 42,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? 'Untitled media' : item.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.category.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (isVideo) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Video playback is not available in this gallery yet.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryStatus extends StatelessWidget {
  final IconData icon;
  final String message;

  const _GalleryStatus({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
