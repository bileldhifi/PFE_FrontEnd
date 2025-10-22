import 'dart:math';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../data/trip_route_repository.dart';
import '../../../trips/data/models/trip.dart';
import '../../../trips/data/models/track_point.dart';

/// Controller for managing trip route visualization on the map
class MapTripController {
  final MapboxMap _mapboxMap;
  final TripRouteRepository _tripRouteRepository;
  
  // Track current annotations for cleanup
  final List<String> _currentPolylineIds = [];
  final List<String> _currentMarkerIds = [];
  
  // Color palette for different trips
  static const List<int> _tripColors = [
    0xFF007AFF, // Blue
    0xFF34C759, // Green
    0xFFFF9500, // Orange
    0xFFFF3B30, // Red
    0xFFAF52DE, // Purple
    0xFFFF2D92, // Pink
    0xFF5AC8FA, // Light Blue
    0xFFFFCC00, // Yellow
  ];

  MapTripController({
    required MapboxMap mapboxMap,
    required TripRouteRepository tripRouteRepository,
  }) : _mapboxMap = mapboxMap,
       _tripRouteRepository = tripRouteRepository;

  /// Load and display all trip routes on the map
  Future<void> loadAndDisplayTripRoutes() async {
    try {
      // Clear existing routes first
      await clearAllAnnotations();
      
      // Fetch all trips
      final trips = await _tripRouteRepository.getAllTrips();
      
      // Display each trip route
      for (int i = 0; i < trips.length; i++) {
        final trip = trips[i];
        await _displayTripRoute(trip, i);
      }
    } catch (e) {
      print('Error loading trip routes: $e');
      rethrow;
    }
  }

  /// Display a single trip route on the map
  Future<void> _displayTripRoute(Trip trip, int colorIndex) async {
    try {
      // Fetch track points for this trip
      final trackPoints = await _tripRouteRepository.getTripTrackPoints(trip.id);
      
      if (trackPoints.isEmpty) return;

      final color = _tripColors[colorIndex % _tripColors.length];
      
      // Create polyline for the route
      await _createTripPolyline(trip, trackPoints, color);
      
      // Add start and end markers
      await _addTripMarkers(trip, trackPoints, color);
    } catch (e) {
      print('Error displaying trip route for ${trip.title}: $e');
      // Continue with other trips even if one fails
    }
  }

  /// Create polyline for trip route
  Future<void> _createTripPolyline(Trip trip, List<TrackPoint> trackPoints, int color) async {
    if (trackPoints.length < 2) return;

    // Convert track points to coordinates
    final coordinates = trackPoints.map((tp) => 
      Position(tp.longitude, tp.latitude)
    ).toList();

    final lineString = LineString(coordinates: coordinates);
    
    // Create polyline annotation
    final polylineManager = await _mapboxMap.annotations.createPolylineAnnotationManager();
    final polylineId = 'trip_${trip.id}_route';
    
    await polylineManager.create(
      PolylineAnnotationOptions(
        geometry: lineString,
        lineColor: color,
        lineWidth: 4.0,
        lineOpacity: 0.8,
      ),
    );
    
    _currentPolylineIds.add(polylineId);
  }

  /// Add start and end markers for trip
  Future<void> _addTripMarkers(Trip trip, List<TrackPoint> trackPoints, int color) async {
    if (trackPoints.isEmpty) return;

    final startPoint = trackPoints.first;
    final endPoint = trackPoints.last;
    
    final pointManager = await _mapboxMap.annotations.createPointAnnotationManager();
    
    // Start marker
    final startMarkerId = 'trip_${trip.id}_start';
    await pointManager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(startPoint.longitude, startPoint.latitude)),
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
        textField: 'Start',
        textSize: 10,
        textColor: 0xFFFFFFFF,
        textHaloColor: color,
        textHaloWidth: 2.0,
      ),
    );
    _currentMarkerIds.add(startMarkerId);
    
    // End marker (only if different from start)
    if (trackPoints.length > 1) {
      final endMarkerId = 'trip_${trip.id}_end';
      await pointManager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(endPoint.longitude, endPoint.latitude)),
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM,
          textField: 'End',
          textSize: 10,
          textColor: 0xFFFFFFFF,
          textHaloColor: color,
          textHaloWidth: 2.0,
        ),
      );
      _currentMarkerIds.add(endMarkerId);
    }
  }

  /// Clear all trip route annotations
  Future<void> clearAllAnnotations() async {
    try {
      // Clear polylines
      final polylineManager = await _mapboxMap.annotations.createPolylineAnnotationManager();
      await polylineManager.deleteAll();
      
      // Clear markers
      final pointManager = await _mapboxMap.annotations.createPointAnnotationManager();
      await pointManager.deleteAll();
      
      // Clear tracking lists
      _currentPolylineIds.clear();
      _currentMarkerIds.clear();
    } catch (e) {
      print('Error clearing annotations: $e');
    }
  }

  /// Display a specific trip route
  Future<void> displaySingleTrip(String tripId) async {
    try {
      await clearAllAnnotations();
      
      final trip = await _tripRouteRepository.getTrip(tripId);
      await _displayTripRoute(trip, 0); // Use first color for single trip
    } catch (e) {
      print('Error displaying single trip: $e');
      rethrow;
    }
  }

  /// Get trip statistics for display
  Future<Map<String, dynamic>> getTripStatistics() async {
    try {
      final trips = await _tripRouteRepository.getAllTrips();
      
      int totalTrips = trips.length;
      double totalDistance = 0.0;
      int totalTrackPoints = 0;
      
      for (final trip in trips) {
        try {
          final trackPoints = await _tripRouteRepository.getTripTrackPoints(trip.id);
          totalTrackPoints += trackPoints.length;
          
          // Calculate distance for each trip
          if (trackPoints.length > 1) {
            totalDistance += _calculateTripDistance(trackPoints);
          }
        } catch (e) {
          print('Error getting track points for trip ${trip.id}: $e');
          // Continue with other trips
        }
      }
      
      return {
        'totalTrips': totalTrips,
        'totalDistance': totalDistance,
        'totalTrackPoints': totalTrackPoints,
        'averageDistance': totalTrips > 0 ? totalDistance / totalTrips : 0.0,
      };
    } catch (e) {
      print('Error getting trip statistics: $e');
      return {
        'totalTrips': 0,
        'totalDistance': 0.0,
        'totalTrackPoints': 0,
        'averageDistance': 0.0,
      };
    }
  }

  /// Calculate approximate distance for a trip (in kilometers)
  double _calculateTripDistance(List<TrackPoint> trackPoints) {
    if (trackPoints.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < trackPoints.length; i++) {
      final prev = trackPoints[i - 1];
      final curr = trackPoints[i];
      totalDistance += _haversineDistance(
        prev.latitude, prev.longitude,
        curr.latitude, curr.longitude,
      );
    }
    return totalDistance;
  }

  /// Haversine formula for calculating distance between two points
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) * 
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * (pi / 180);
}
