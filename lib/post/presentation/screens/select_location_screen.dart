import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../trips/data/models/trip.dart';
import '../../../trips/data/models/track_point.dart';
import '../widgets/current_location_card.dart';
import '../widgets/location_card.dart';

/// Screen for selecting a location for post creation
/// Optimized to use cached data from map screen - no duplicate API calls
class SelectLocationScreen extends StatelessWidget {
  final geo.Position? cachedLocation;
  final List<Trip>? cachedTrips;
  final Map<String, List<TrackPoint>>? cachedTrackPoints;

  const SelectLocationScreen({
    super.key,
    this.cachedLocation,
    this.cachedTrips,
    this.cachedTrackPoints,
  });

  void _selectLocation(
    BuildContext context,
    String locationType, {
    TrackPoint? trackPoint,
    String? tripId,
  }) {
    // Prepare location data to pass to create post screen
    final locationData = {
      'type': locationType,
      if (tripId != null) 'tripId': tripId,
      if (locationType == 'current' && cachedLocation != null) ...{
        'latitude': cachedLocation!.latitude,
        'longitude': cachedLocation!.longitude,
        'address': 'Current Location',
      },
      if (trackPoint != null) ...{
        'latitude': trackPoint.latitude,
        'longitude': trackPoint.longitude,
        'address': trackPoint.locationName ?? 'Track Point',
        'trackPointId': trackPoint.id,
      },
    };

    context.push('/post/create', extra: locationData);
  }

  @override
  Widget build(BuildContext context) {
    final trips = cachedTrips ?? [];
    final trackPointsMap = cachedTrackPoints ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: _HeaderSection(),
          ),

          // Current Location Section
          if (cachedLocation != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                ),
                child: CurrentLocationCard(
                  position: cachedLocation!,
                  isSelected: false,
                  onTap: () => _selectLocation(
                    context,
                    'current',
                    tripId: trips.isNotEmpty ? trips.first.id : null,
                  ),
                ),
              ),
            ),

          // Track Points Section Header
          if (trips.isNotEmpty)
            const SliverToBoxAdapter(
              child: _TrackPointsSectionHeader(),
            ),

          // Trip and Track Points List
          ...trips.map((trip) {
            final trackPoints = trackPointsMap[trip.id] ?? [];
            if (trackPoints.isEmpty) {
              return const SliverToBoxAdapter(
                child: SizedBox.shrink(),
              );
            }

            return SliverToBoxAdapter(
              child: _TripTrackPointsSection(
                trip: trip,
                trackPoints: trackPoints,
                onSelectLocation: (trackPoint) => _selectLocation(
                  context,
                  'trackpoint',
                  trackPoint: trackPoint,
                  tripId: trip.id,
                ),
              ),
            );
          }).toList(),

          // Empty state
          if (cachedLocation == null && trips.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }
}

/// Header section widget
class _HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a location for your post',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your current location or choose from '
            'an existing track point',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

/// Track points section header widget
class _TrackPointsSectionHeader extends StatelessWidget {
  const _TrackPointsSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      child: Text(
        'Select from Track Points',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Trip track points section widget
class _TripTrackPointsSection extends StatelessWidget {
  final Trip trip;
  final List<TrackPoint> trackPoints;
  final void Function(TrackPoint) onSelectLocation;

  const _TripTrackPointsSection({
    required this.trip,
    required this.trackPoints,
    required this.onSelectLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip header
          _TripHeader(
            trip: trip,
            trackPointsCount: trackPoints.length,
          ),
          // All track points
          ...trackPoints.map((trackPoint) {
            return LocationCard(
              trackPoint: trackPoint,
              tripTitle: trip.title,
              isSelected: false,
              onTap: () => onSelectLocation(trackPoint),
            );
          }),
        ],
      ),
    );
  }
}

/// Trip header widget
class _TripHeader extends StatelessWidget {
  final Trip trip;
  final int trackPointsCount;

  const _TripHeader({
    required this.trip,
    required this.trackPointsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            Icons.luggage,
            size: 20,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trip.title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
            ),
          ),
          Text(
            '$trackPointsCount ${trackPointsCount == 1 ? "point" : "points"}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

/// Empty state widget
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No locations available',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to the map screen first to load locations',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
