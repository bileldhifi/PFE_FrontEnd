import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/loading_widget.dart';
import 'package:travel_diary_frontend/core/widgets/retry_widget.dart';
import 'package:travel_diary_frontend/trips/data/models/timeline_item.dart';
import 'package:travel_diary_frontend/trips/presentation/controllers/trip_timeline_controller.dart';

/// Base URL for media
const String _baseMediaUrl = 'http://localhost:8089/app-backend';

/// Modern timeline tab with track points and media
class ModernTimelineTab extends ConsumerWidget {
  final String tripId;

  const ModernTimelineTab({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      tripTimelineControllerProvider(tripId),
    );

    log('🎨 [UI] Building timeline - '
        'isLoading: ${state.isLoading}, '
        'hasTimeline: ${state.timeline != null}, '
        'items: ${state.timeline?.items.length ?? 0}, '
        'error: ${state.error}');

    if (state.isLoading && state.timeline == null) {
      log('🎨 [UI] Showing loading state');
      return const Center(child: LoadingWidget());
    }

    if (state.error != null && state.timeline == null) {
      log('🎨 [UI] Showing error state: ${state.error}');
      return RetryWidget(
        message: state.error!,
        onRetry: () => ref
            .read(tripTimelineControllerProvider(tripId).notifier)
            .refresh(),
      );
    }

    final timeline = state.timeline;
    if (timeline == null || timeline.items.isEmpty) {
      log('🎨 [UI] Showing empty state - '
          'timeline null: ${timeline == null}, '
          'items empty: ${timeline?.items.isEmpty ?? true}');
      return const EmptyState(
        icon: Icons.timeline_outlined,
        title: 'No Journey Data',
        message: 'Track points will appear as you travel',
      );
    }

    log('🎨 [UI] Rendering ${timeline.items.length} timeline items');

    return RefreshIndicator(
      onRefresh: () => ref
          .read(tripTimelineControllerProvider(tripId).notifier)
          .refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 80,
        ),
        itemCount: timeline.items.length,
        itemBuilder: (context, index) {
          final item = timeline.items[index];
          final isFirst = index == 0;
          final isLast = index == timeline.items.length - 1;

          return _TimelineItemCard(
            item: item,
            isFirst: isFirst,
            isLast: isLast,
          );
        },
      ),
    );
  }
}

/// Responsive helper for timeline
class _ResponsiveTimeline {
  final BuildContext context;
  
  late final double screenWidth;
  late final double timelineWidth;
  late final double dotSize;
  late final double cardPadding;
  late final int photoGridColumns;
  
  _ResponsiveTimeline(this.context) {
    screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 600) {
      // Mobile
      timelineWidth = 40;
      dotSize = 20;
      cardPadding = 12;
      photoGridColumns = 2;
    } else if (screenWidth < 1200) {
      // Tablet
      timelineWidth = 60;
      dotSize = 24;
      cardPadding = 16;
      photoGridColumns = 3;
    } else {
      // Desktop
      timelineWidth = 80;
      dotSize = 28;
      cardPadding = 20;
      photoGridColumns = 4;
    }
  }
}

/// Timeline item card
class _TimelineItemCard extends StatefulWidget {
  final TimelineItem item;
  final bool isFirst;
  final bool isLast;

  const _TimelineItemCard({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_TimelineItemCard> createState() => _TimelineItemCardState();
}

class _TimelineItemCardState extends State<_TimelineItemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final responsive = _ResponsiveTimeline(context);
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        SizedBox(
          width: responsive.timelineWidth,
          child: Column(
            children: [
              if (!widget.isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              _TimelineDot(
                item: widget.item,
                size: responsive.dotSize,
              ),
              if (!widget.isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              child: InkWell(
                onTap: () {
                  if (widget.item.posts.isNotEmpty) {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(responsive.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(context, responsive),

                      SizedBox(height: responsive.cardPadding),

                      // Photo Grid
                      if (widget.item.hasMedia) ...[
                        _buildPhotoGrid(
                          context, 
                          responsive,
                        ),
                        SizedBox(height: responsive.cardPadding),
                      ],

                      // Caption
                      if (widget.item.posts.isNotEmpty &&
                          widget.item.posts.first.text.isNotEmpty) ...[
                        _buildCaption(context),
                        const SizedBox(height: 12),
                      ],

                      // Stats Bar
                      _buildStatsBar(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context, 
    _ResponsiveTimeline responsive,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              _formatTime(widget.item.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Location
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.item.formattedLocation,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        // Distance from previous
        if (widget.item.distanceFromPreviousKm != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.straight,
                size: 14,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.item.formattedDistanceFromPrevious} from previous',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPhotoGrid(
    BuildContext context,
    _ResponsiveTimeline responsive,
  ) {
    final photos = widget.item.posts
        .expand((post) => post.media)
        .toList();

    if (photos.isEmpty) return const SizedBox.shrink();

    if (photos.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => _openMediaViewer(context),
          child: CachedNetworkImage(
            imageUrl: '$_baseMediaUrl${photos[0].url}',
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: responsive.photoGridColumns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length > 4 ? 4 : photos.length,
      itemBuilder: (context, index) {
        if (index == 3 && photos.length > 4) {
          return _buildMorePhotosOverlay(
            context,
            photos[index].url,
            photos.length - 4,
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () => _openMediaViewer(context),
            child: CachedNetworkImage(
              imageUrl: '$_baseMediaUrl${photos[index].url}',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey.shade200,
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMorePhotosOverlay(
    BuildContext context,
    String imageUrl,
    int remainingCount,
  ) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _openMediaViewer(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: '$_baseMediaUrl$imageUrl',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaption(BuildContext context) {
    final theme = Theme.of(context);
    final caption = widget.item.posts.first.text;
    final hasLongText = caption.length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          style: theme.textTheme.bodyMedium,
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (hasLongText) ...[
          TextButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
            ),
            child: Text(_isExpanded ? 'Show less' : 'Read more'),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Speed
        if (widget.item.speedKmh != null)
          _StatChip(
            icon: _getSpeedIcon(widget.item.speedKmh!),
            label: widget.item.formattedSpeed,
            color: theme.colorScheme.primary,
          ),
        
        // Accuracy
        if (widget.item.accuracyMeters != null)
          _StatChip(
            icon: Icons.gps_fixed,
            label: widget.item.formattedAccuracy,
            color: Colors.green,
          ),
        
        // Photo count
        if (widget.item.photoCount > 0)
          _StatChip(
            icon: Icons.photo_camera,
            label: '${widget.item.photoCount} photo${widget.item.photoCount > 1 ? 's' : ''}',
            color: Colors.purple,
          ),
      ],
    );
  }

  IconData _getSpeedIcon(double speedKmh) {
    if (speedKmh < 1) return Icons.place;
    if (speedKmh < 5) return Icons.directions_walk;
    if (speedKmh < 15) return Icons.directions_run;
    if (speedKmh < 50) return Icons.directions_bike;
    if (speedKmh < 120) return Icons.directions_car;
    return Icons.flight;
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • HH:mm').format(dateTime);
  }

  void _openMediaViewer(BuildContext context) {
    if (widget.item.posts.isEmpty) return;
    
    context.push(
      '/post/media/${widget.item.trackPointId}'
      '?location=${Uri.encodeComponent(widget.item.formattedLocation)}',
    );
  }
}

/// Timeline dot widget
class _TimelineDot extends StatelessWidget {
  final TimelineItem item;
  final double size;

  const _TimelineDot({
    required this.item,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor(theme);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: theme.colorScheme.surface,
          width: 3,
        ),
        boxShadow: item.isSignificant
            ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Icon(
        _getIcon(),
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }

  Color _getColor(ThemeData theme) {
    if (item.isSignificant) {
      return Colors.orange;
    }
    if (item.hasMedia) {
      return Colors.purple;
    }
    return theme.colorScheme.primary;
  }

  IconData _getIcon() {
    if (item.hasMedia) {
      return Icons.photo_camera;
    }
    if (item.speedKmh != null) {
      if (item.speedKmh! < 1) return Icons.place;
      if (item.speedKmh! < 5) return Icons.directions_walk;
      if (item.speedKmh! < 15) return Icons.directions_run;
      if (item.speedKmh! < 50) return Icons.directions_bike;
      if (item.speedKmh! < 120) return Icons.directions_car;
      return Icons.flight;
    }
    return Icons.location_on;
  }
}

/// Stat chip widget
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

