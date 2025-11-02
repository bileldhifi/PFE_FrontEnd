import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/loading_widget.dart';
import 'package:travel_diary_frontend/trips/presentation/simple_timeline_tab.dart';
import 'package:travel_diary_frontend/trips/presentation/widgets/simple_image_viewer.dart';

/// Base URL for media
const String _kBaseUrl = 'http://localhost:8089/app-backend';

/// Gallery filter options
enum GalleryFilter {
  all,
  photos,
  videos,
  favorites,
}

/// Beautiful gallery tab with grid layout
class BeautifulGalleryTab extends ConsumerStatefulWidget {
  final String tripId;

  const BeautifulGalleryTab({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<BeautifulGalleryTab> createState() =>
      _BeautifulGalleryTabState();
}

class _BeautifulGalleryTabState extends ConsumerState<BeautifulGalleryTab> {
  GalleryFilter _currentFilter = GalleryFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncTimeline = ref.watch(simpleTimelineProvider(widget.tripId));

    return asyncTimeline.when(
      data: (timeline) {
        log('🎨 [GALLERY] Timeline items: ${timeline.items.length}');
        
        // Collect all media from timeline items
        final allMedia = <_MediaItem>[];
        for (final item in timeline.items) {
          for (final post in item.posts) {
            if (post.media.isNotEmpty) {
              for (final media in post.media) {
                allMedia.add(
                  _MediaItem(
                    url: media.url,
                    stepName: item.locationName,
                    trackPointId: item.trackPointId.toString(),
                    isVideo: media.type == 'VIDEO',
                  ),
                );
              }
            }
          }
        }

        log('🎨 [GALLERY] Total media items: ${allMedia.length}');

        // Apply filter
        final filteredMedia = _applyFilter(allMedia);
        
        log('🎨 [GALLERY] Filtered media: ${filteredMedia.length}');

        if (filteredMedia.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surfaceContainerLow,
                ],
              ),
            ),
            child: const EmptyState(
              icon: Icons.photo_library_outlined,
              title: 'No Photos Yet',
              message: 'Add photos to your journey to see them here',
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerLow,
              ],
            ),
          ),
          child: Column(
            children: [
              // Filter chips
              _buildFilterBar(theme, filteredMedia.length),
              
              // Gallery grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filteredMedia.length,
                  itemBuilder: (context, index) {
                    final item = filteredMedia[index];
                    return _GalleryTile(
                      item: item,
                      onTap: () {
                        // Get all image URLs from filtered media
                        final allUrls = filteredMedia
                            .map((m) => m.url)
                            .toList();
                        SimpleImageViewer.show(
                          context,
                          imageUrls: allUrls,
                          initialIndex: index,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) {
        log('🎨 [GALLERY] Error: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading gallery: $error'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(ThemeData theme, int itemCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '$itemCount Photos',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  icon: Icons.grid_view_rounded,
                  isSelected: _currentFilter == GalleryFilter.all,
                  onTap: () => setState(() => _currentFilter = GalleryFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Photos',
                  icon: Icons.photo_rounded,
                  isSelected: _currentFilter == GalleryFilter.photos,
                  onTap: () => setState(() => _currentFilter = GalleryFilter.photos),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Videos',
                  icon: Icons.videocam_rounded,
                  isSelected: _currentFilter == GalleryFilter.videos,
                  onTap: () => setState(() => _currentFilter = GalleryFilter.videos),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Favorites',
                  icon: Icons.favorite_rounded,
                  isSelected: _currentFilter == GalleryFilter.favorites,
                  onTap: () => setState(() => _currentFilter = GalleryFilter.favorites),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_MediaItem> _applyFilter(List<_MediaItem> media) {
    switch (_currentFilter) {
      case GalleryFilter.all:
        return media;
      case GalleryFilter.photos:
        return media.where((m) => !m.isVideo).toList();
      case GalleryFilter.videos:
        return media.where((m) => m.isVideo).toList();
      case GalleryFilter.favorites:
        return media.where((m) => m.isFavorite).toList();
    }
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                )
              : null,
          color: isSelected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gallery tile widget
class _GalleryTile extends StatelessWidget {
  final _MediaItem item;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'photo_${item.url}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: '$_kBaseUrl${item.url}',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.surfaceContainerHighest,
                          theme.colorScheme.surfaceContainer,
                        ],
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.colorScheme.errorContainer,
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                
                // Video overlay
                if (item.isVideo)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                
                // Location badge
                if (item.stepName != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.stepName!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Media item model
class _MediaItem {
  final String url;
  final String? stepName;
  final String? trackPointId;
  final bool isVideo;
  final bool isFavorite;

  _MediaItem({
    required this.url,
    this.stepName,
    this.trackPointId,
    this.isVideo = false,
    this.isFavorite = false,
  });
}

