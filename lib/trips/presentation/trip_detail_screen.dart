import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/core/utils/date_time.dart';
import 'package:travel_diary_frontend/core/widgets/app_network_image.dart';
import 'package:travel_diary_frontend/core/widgets/retry_widget.dart';
import 'package:travel_diary_frontend/core/widgets/visibility_badge.dart';
import 'package:travel_diary_frontend/trips/presentation/controllers/trip_detail_controller.dart';
import 'package:travel_diary_frontend/trips/presentation/beautiful_gallery_tab.dart';
import 'package:travel_diary_frontend/trips/presentation/trip_map_tab.dart';
import 'package:travel_diary_frontend/trips/presentation/simple_timeline_tab.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tripDetailControllerProvider(tripId));

    if (state.isLoading && state.trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && state.trip == null) {
      return Scaffold(
        appBar: AppBar(),
        body: RetryWidget(
          message: state.error!,
          onRetry: () => ref.read(tripDetailControllerProvider(tripId).notifier).loadTripDetail(),
        ),
      );
    }

    final trip = state.trip!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Collapsing header with cover image
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (trip.coverUrl != null)
                        AppNetworkImage(
                          imageUrl: trip.coverUrl!,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      else
                        Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),

                      // Trip info overlay
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    trip.title,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                VisibilityBadge(
                                  visibility: _getVisibilityType(trip.visibility),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateTimeUtils.formatDateRange(trip.startDate, trip.endDate),
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    onPressed: () {
                      context.push('/trips/$tripId/track-points?title=${Uri.encodeComponent(trip.title)}');
                    },
                    tooltip: 'Track Points',
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit coming soon!')),
                        );
                      } else if (value == 'share') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share coming soon!')),
                        );
                      } else if (value == 'delete') {
                        _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Edit Trip'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined),
                            SizedBox(width: 12),
                            Text('Share'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Stats bar
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Main stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEnhancedStatItem(
                            context,
                            icon: Icons.route_rounded,
                            value: '${trip.stats.distanceKm.toStringAsFixed(1)} km',
                            label: 'Distance',
                            color: Colors.blue,
                          ),
                          _buildEnhancedStatItem(
                            context,
                            icon: Icons.photo_library_rounded,
                            value: '${trip.stats.photosCount}',
                            label: 'Photos',
                            color: Colors.purple,
                          ),
                          _buildEnhancedStatItem(
                            context,
                            icon: Icons.place_rounded,
                            value: '${trip.stats.countriesCount}',
                            label: 'Countries',
                            color: Colors.green,
                          ),
                          _buildEnhancedStatItem(
                            context,
                            icon: Icons.location_city_rounded,
                            value: '${trip.stats.citiesCount}',
                            label: 'Cities',
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      
                      // Duration
                      if (trip.endDate != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDuration(trip.startDate, trip.endDate!),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Transport methods (if available)
              if (trip.stats.transportMethods.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.directions_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Transport Methods',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...trip.stats.transportMethods.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _getTransportColor(entry.key).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getTransportIcon(entry.key),
                                    size: 20,
                                    color: _getTransportColor(entry.key),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '${entry.value.toStringAsFixed(1)} km',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _getTransportColor(entry.key),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // Tab bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    tabs: const [
                      Tab(text: 'Timeline'),
                      Tab(text: 'Map'),
                      Tab(text: 'Gallery'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              SimpleTimelineTab(tripId: tripId),
              TripMapTab(steps: state.steps),
              BeautifulGalleryTab(tripId: tripId),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add step coming soon!')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Step'),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildEnhancedStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
  
  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? "s" : ""}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? "s" : ""}';
    } else {
      return '${duration.inMinutes} min';
    }
  }
  
  IconData _getTransportIcon(String method) {
    switch (method.toLowerCase()) {
      case 'walking':
        return Icons.directions_walk_rounded;
      case 'biking':
        return Icons.directions_bike_rounded;
      case 'driving':
        return Icons.directions_car_rounded;
      case 'flying':
        return Icons.flight_rounded;
      default:
        return Icons.help_outline;
    }
  }
  
  Color _getTransportColor(String method) {
    switch (method.toLowerCase()) {
      case 'walking':
        return Colors.green;
      case 'biking':
        return Colors.orange;
      case 'driving':
        return Colors.blue;
      case 'flying':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  VisibilityType _getVisibilityType(String visibility) {
    switch (visibility.toUpperCase()) {
      case 'PUBLIC':
        return VisibilityType.public;
      case 'FRIENDS':
        return VisibilityType.friends;
      case 'PRIVATE':
        return VisibilityType.private;
      default:
        return VisibilityType.friends;
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete trip and navigate back
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Sliver tab bar delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

