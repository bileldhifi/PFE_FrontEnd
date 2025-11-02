import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/loading_widget.dart';
import 'package:travel_diary_frontend/trips/data/models/timeline_response.dart';
import 'package:travel_diary_frontend/trips/data/repo/trip_repository.dart';
import 'package:travel_diary_frontend/trips/presentation/widgets/simple_image_viewer.dart';

/// Base URL for media
const String _kBaseUrl = 'http://localhost:8089/app-backend';

/// Simple timeline provider - just fetches data
final simpleTimelineProvider = FutureProvider.family<TimelineResponse, String>(
  (ref, tripId) async {
    log('📱 [SIMPLE] Fetching timeline for trip: $tripId');
    final repository = TripRepository();
    final result = await repository.getTimeline(tripId);
    log('📱 [SIMPLE] Got ${result.items.length} items');
    return result;
  },
);

/// Simple timeline tab - beautiful design
class SimpleTimelineTab extends ConsumerWidget {
  final String tripId;

  const SimpleTimelineTab({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTimeline = ref.watch(simpleTimelineProvider(tripId));

    return asyncTimeline.when(
      data: (timeline) {
        log('📱 [SIMPLE UI] Rendering ${timeline.items.length} items');
        
        if (timeline.items.isEmpty) {
          return const EmptyState(
            icon: Icons.timeline_outlined,
            title: 'No Journey Data',
            message: 'Track points will appear as you travel',
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surfaceContainerLow,
              ],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(simpleTimelineProvider(tripId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: timeline.items.length,
              itemBuilder: (context, index) {
                final item = timeline.items[index];
                final isFirst = index == 0;
                final isLast = index == timeline.items.length - 1;
                
                return _BeautifulTimelineCard(
                  item: item,
                  isFirst: isFirst,
                  isLast: isLast,
                );
              },
            ),
          ),
        );
      },
      loading: () {
        log('📱 [SIMPLE UI] Loading...');
        return const Center(child: LoadingWidget());
      },
      error: (error, stack) {
        log('📱 [SIMPLE UI] Error: $error');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops! Something went wrong',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(simpleTimelineProvider(tripId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Beautiful timeline card with timeline indicator
class _BeautifulTimelineCard extends StatelessWidget {
  final dynamic item;
  final bool isFirst;
  final bool isLast;

  const _BeautifulTimelineCard({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhotos = item.posts != null && 
        item.posts.isNotEmpty &&
        item.posts.any((p) => p.media != null && p.media.isNotEmpty);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Top line
              if (!isFirst)
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.outlineVariant.withOpacity(0.3),
                        theme.colorScheme.outlineVariant,
                      ],
                    ),
                  ),
                ),
              
              // Dot
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasPhotos 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.outline,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (hasPhotos 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.outline).withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: hasPhotos
                    ? Icon(
                        Icons.camera_alt_rounded,
                        size: 12,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              
              // Bottom line
              if (!isLast)
                Container(
                  width: 3,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.colorScheme.outlineVariant,
                        theme.colorScheme.outlineVariant.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Content card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Header with time
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer.withOpacity(0.3),
                            theme.colorScheme.primaryContainer.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(item.timestamp),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatTime(item.timestamp),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            label: 'Location',
                            value: '${item.latitude.toStringAsFixed(4)}, '
                                '${item.longitude.toStringAsFixed(4)}',
                            color: theme.colorScheme.error,
                          ),
                          
                          // Distance & Speed
                          if (item.distanceFromPreviousKm != null || 
                              item.speedKmh != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (item.distanceFromPreviousKm != null)
                                  Expanded(
                                    child: _StatChip(
                                      icon: Icons.straighten_rounded,
                                      label: '${item.distanceFromPreviousKm!.toStringAsFixed(2)} km',
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                if (item.distanceFromPreviousKm != null && 
                                    item.speedKmh != null)
                                  const SizedBox(width: 8),
                                if (item.speedKmh != null)
                                  Expanded(
                                    child: _StatChip(
                                      icon: _getSpeedIcon(item.speedKmh!),
                                      label: '${item.speedKmh!.toStringAsFixed(1)} km/h',
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          
                          // Photos
                          if (hasPhotos) ...[
                            const SizedBox(height: 16),
                            _buildPhotos(context, item.posts, theme),
                          ],
                          
                          // Caption
                          if (item.posts != null && 
                              item.posts.isNotEmpty && 
                              item.posts[0].text != null &&
                              item.posts[0].text.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.format_quote_rounded,
                                    size: 20,
                                    color: theme.colorScheme.outline,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.posts[0].text,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotos(
    BuildContext context,
    List<dynamic> posts,
    ThemeData theme,
  ) {
    final photos = <String>[];
    for (final post in posts) {
      if (post.media != null) {
        for (final media in post.media) {
          photos.add(media.url);
        }
      }
    }
    
    if (photos.isEmpty) return const SizedBox.shrink();
    
    if (photos.length == 1) {
      return GestureDetector(
        onTap: () {
          SimpleImageViewer.show(
            context,
            imageUrls: photos,
            initialIndex: 0,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: '$_kBaseUrl${photos[0]}',
            height: 240,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHighest,
                    theme.colorScheme.surfaceContainer,
                  ],
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 240,
              color: theme.colorScheme.errorContainer,
              child: Icon(
                Icons.broken_image_rounded,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length > 4 ? 4 : photos.length,
      itemBuilder: (context, index) {
        if (index == 3 && photos.length > 4) {
          return GestureDetector(
            onTap: () {
              SimpleImageViewer.show(
                context,
                imageUrls: photos,
                initialIndex: 3,
              );
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: '$_kBaseUrl${photos[index]}',
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${photos.length - 3}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'more',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        return GestureDetector(
          onTap: () {
            SimpleImageViewer.show(
              context,
              imageUrls: photos,
              initialIndex: index,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: '$_kBaseUrl${photos[index]}',
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.errorContainer,
                child: Icon(
                  Icons.broken_image_rounded,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('EEEE, MMM d, yyyy').format(dateTime);
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  IconData _getSpeedIcon(double speedKmh) {
    if (speedKmh < 1) return Icons.place_rounded;
    if (speedKmh < 5) return Icons.directions_walk_rounded;
    if (speedKmh < 15) return Icons.directions_run_rounded;
    if (speedKmh < 50) return Icons.directions_bike_rounded;
    if (speedKmh < 120) return Icons.directions_car_rounded;
    return Icons.flight_rounded;
  }
}

/// Info row with icon and text
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stat chip for distance/speed
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

