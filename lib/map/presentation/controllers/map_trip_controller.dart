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
  
  // Cache loaded data for reuse (optimization - avoid duplicate API calls)
  List<Trip> trips = [];
  Map<String, List<TrackPoint>> trackPoints = {};
  
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
      
      // Fetch all trips and cache them
      trips = await _tripRouteRepository.getAllTrips();
      
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
      print('Displaying trip route for: ${trip.title} (ID: ${trip.id})');
      
      // Fetch track points for this trip and cache them
      final tripTrackPoints = await _tripRouteRepository.getTripTrackPoints(trip.id);
      trackPoints[trip.id] = tripTrackPoints; // Cache for reuse
      
      print('Fetched ${tripTrackPoints.length} track points for trip ${trip.id}');
      
      if (tripTrackPoints.isEmpty) {
        print('No track points found for trip ${trip.id}');
        return;
      }

      final color = _tripColors[colorIndex % _tripColors.length];
      
      // Create polyline for the route
      await _createTripPolyline(trip, tripTrackPoints, color);
      print('Created polyline for trip ${trip.id}');
      
      // Add start and end markers
      await _addTripMarkers(trip, tripTrackPoints, color);
      print('Added markers for trip ${trip.id}');
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
        lineWidth: 5.0, // Slightly thicker for better visibility
        lineOpacity: 0.9, // More opaque
        // Note: linePattern might not be supported in this version, removed for compatibility
      ),
    );
    
    _currentPolylineIds.add(polylineId);
  }

  /// Add enhanced start and end markers for trip
  Future<void> _addTripMarkers(Trip trip, List<TrackPoint> trackPoints, int color) async {
    if (trackPoints.isEmpty) return;

    final startPoint = trackPoints.first;
    final endPoint = trackPoints.last;
    
    final pointManager = await _mapboxMap.annotations.createPointAnnotationManager();
    
    // Enhanced Start marker with icon
    final startMarkerId = 'trip_${trip.id}_start';
    await pointManager.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(startPoint.longitude, startPoint.latitude)),
        iconSize: 1.2,
        iconAnchor: IconAnchor.BOTTOM,
        textField: '🚀 Start',
        textSize: 12,
        textColor: 0xFFFFFFFF,
        textHaloColor: 0xFF4CAF50, // Green halo for start
        textHaloWidth: 3.0,
        textOffset: [0.0, -2.0],
      ),
    );
    _currentMarkerIds.add(startMarkerId);
    
    // Enhanced End marker with icon (only if different from start)
    if (trackPoints.length > 1) {
      final endMarkerId = 'trip_${trip.id}_end';
      await pointManager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(endPoint.longitude, endPoint.latitude)),
          iconSize: 1.2,
          iconAnchor: IconAnchor.BOTTOM,
          textField: '🏁 End',
          textSize: 12,
          textColor: 0xFFFFFFFF,
          textHaloColor: 0xFFF44336, // Red halo for end
          textHaloWidth: 3.0,
          textOffset: [0.0, -2.0],
        ),
      );
      _currentMarkerIds.add(endMarkerId);
    }
    
    // Add individual track point markers (every 5th point to avoid clutter)
    await _addTrackPointMarkers(trip, trackPoints, color, pointManager);
  }

  /// Add individual track point markers along the route
  Future<void> _addTrackPointMarkers(Trip trip, List<TrackPoint> trackPoints, int color, dynamic pointManager) async {
    if (trackPoints.length < 3) return; // Don't add individual markers for very short routes
    
    print('Adding track point markers for trip ${trip.id}: ${trackPoints.length} total points');
    
    // Show ALL track points for maximum visibility and future media integration
    int stepSize = 1; // Always show every point for complete visualization
    if (trackPoints.length > 1000) stepSize = 2; // Only reduce for extremely long routes
    
    print('Using step size: $stepSize');
    
    int markersAdded = 0;
    
    // Add markers for track points with enhanced visibility
    for (int i = 0; i < trackPoints.length; i += stepSize) {
      final trackPoint = trackPoints[i];
      
      // Skip start and end points as they have special markers
      if (i == 0 || i == trackPoints.length - 1) continue;
      
      final markerId = 'trip_${trip.id}_point_$i';
      try {
        // Enhanced marker styles for better visibility and future media integration
        String markerIcon;
        double markerSize;
        double textSize;
        int haloWidth;
        int haloColor;
        
        // Check if track point has media (for future implementation)
        bool hasMedia = trackPoint.isSignificant; // Use existing field for now
        
        // Create different marker styles based on significance and media
        if (hasMedia) {
          // Media points - most prominent
          markerIcon = '📸'; // Camera icon for points with media
          markerSize = 1.8; // Larger for media points
          textSize = 14;
          haloWidth = 5;
          haloColor = 0xFFFF6B35; // Orange for media points
        } else if (i % 20 == 0) {
          // Major waypoints - very visible
          markerIcon = '⭐'; // Star for major waypoints
          markerSize = 1.6;
          textSize = 13;
          haloWidth = 4;
          haloColor = 0xFFFFD700; // Gold for major waypoints
        } else if (i % 10 == 0) {
          // Significant points - highly visible
          markerIcon = '🔵'; // Blue circle for significant points
          markerSize = 1.4;
          textSize = 12;
          haloWidth = 4;
          haloColor = 0xFF2196F3; // Blue for significant points
        } else if (i % 5 == 0) {
          // Medium points - visible
          markerIcon = '🟢'; // Green circle for medium points
          markerSize = 1.2;
          textSize = 11;
          haloWidth = 3;
          haloColor = 0xFF4CAF50; // Green for medium points
        } else {
          // Regular points - always visible
          markerIcon = '📍'; // Pin for regular points
          markerSize = 1.0;
          textSize = 10;
          haloWidth = 3;
          haloColor = color; // Use trip color for regular points
        }
        
        await pointManager.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(trackPoint.longitude, trackPoint.latitude)),
            iconSize: markerSize,
            iconAnchor: IconAnchor.CENTER,
            textField: markerIcon,
            textSize: textSize,
            textColor: 0xFFFFFFFF,
            textHaloColor: haloColor,
            textHaloWidth: haloWidth.toDouble(),
            // Enhanced offset for better visual separation
            textOffset: [0.0, -1.5],
          ),
        );
        _currentMarkerIds.add(markerId);
        markersAdded++;
        print('Added track point marker $markerId at ${trackPoint.latitude}, ${trackPoint.longitude}');
      } catch (e) {
        print('Error creating track point marker $markerId: $e');
      }
    }
    
    print('Successfully added $markersAdded track point markers for trip ${trip.id}');
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

  /// Add trip information popup at a specific location
  Future<void> addTripInfoPopup(Trip trip, double latitude, double longitude) async {
    try {
      final pointManager = await _mapboxMap.annotations.createPointAnnotationManager();
      
      await pointManager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(longitude, latitude)),
          iconSize: 1.0,
          iconAnchor: IconAnchor.BOTTOM,
          textField: 'ℹ️ ${trip.title}',
          textSize: 11,
          textColor: 0xFFFFFFFF,
          textHaloColor: 0xFF2196F3, // Blue halo for info
          textHaloWidth: 3.0,
          textOffset: [0.0, -2.0],
        ),
      );
      
      _currentMarkerIds.add('trip_${trip.id}_info');
    } catch (e) {
      print('Error adding trip info popup: $e');
    }
  }

  /// Add track points with custom density level
  Future<void> addTrackPointsWithDensity(Trip trip, List<TrackPoint> trackPoints, int color, String density) async {
    if (trackPoints.isEmpty) return;
    
    final pointManager = await _mapboxMap.annotations.createPointAnnotationManager();
    print('Adding track points with density: $density for trip ${trip.id}');
    
    int stepSize;
    String markerIcon;
    double markerSize;
    double textSize;
    double haloWidth;
    int haloColor;
    
    switch (density.toLowerCase()) {
      case 'high':
        stepSize = 1; // Every point - maximum detail
        markerIcon = '📍';
        markerSize = 1.0; // Increased for better visibility
        textSize = 10;
        haloWidth = 3.0; // Increased for better visibility
        haloColor = color;
        break;
      case 'medium':
        stepSize = 2; // Every 2nd point - still high detail
        markerIcon = '🔵';
        markerSize = 1.2; // Larger for better visibility
        textSize = 11;
        haloWidth = 3.5;
        haloColor = 0xFF2196F3; // Blue
        break;
      case 'low':
        stepSize = 5; // Every 5th point - overview mode
        markerIcon = '⭐';
        markerSize = 1.4; // Larger for overview
        textSize = 12;
        haloWidth = 4.0;
        haloColor = 0xFFFFD700; // Gold
        break;
      default:
        stepSize = 1; // Default to high density
        markerIcon = '📍';
        markerSize = 1.0;
        textSize = 10;
        haloWidth = 3.0;
        haloColor = color;
    }
    
    int markersAdded = 0;
    
    for (int i = 0; i < trackPoints.length; i += stepSize) {
      final trackPoint = trackPoints[i];
      
      // Skip start and end points
      if (i == 0 || i == trackPoints.length - 1) continue;
      
      final markerId = 'trip_${trip.id}_${density}_$i';
      try {
        await pointManager.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(trackPoint.longitude, trackPoint.latitude)),
            iconSize: markerSize,
            iconAnchor: IconAnchor.CENTER,
            textField: markerIcon,
            textSize: textSize,
            textColor: 0xFFFFFFFF,
            textHaloColor: haloColor,
            textHaloWidth: haloWidth,
            textOffset: [0.0, -1.5], // Enhanced offset
          ),
        );
        _currentMarkerIds.add(markerId);
        markersAdded++;
      } catch (e) {
        print('Error creating track point marker $markerId: $e');
      }
    }
    
    print('Successfully added $markersAdded track point markers with $density density');
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

  /// Add track point with media marker (for future media integration)
  Future<void> addTrackPointWithMedia(Trip trip, TrackPoint trackPoint, int color, String mediaType) async {
    if (_mapboxMap == null) return;
    
    final pointManager = await _mapboxMap!.annotations.createPointAnnotationManager();
    
    String markerIcon;
    int haloColor;
    
    // Different icons based on media type
    switch (mediaType.toLowerCase()) {
      case 'photo':
        markerIcon = '📸';
        haloColor = 0xFFFF6B35; // Orange
        break;
      case 'video':
        markerIcon = '🎥';
        haloColor = 0xFF9C27B0; // Purple
        break;
      case 'audio':
        markerIcon = '🎵';
        haloColor = 0xFF4CAF50; // Green
        break;
      case 'note':
        markerIcon = '📝';
        haloColor = 0xFF2196F3; // Blue
        break;
      default:
        markerIcon = '📸';
        haloColor = 0xFFFF6B35; // Orange
    }
    
    final markerId = 'trip_${trip.id}_media_${trackPoint.id}';
    try {
      await pointManager.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(trackPoint.longitude, trackPoint.latitude)),
          iconSize: 2.0, // Large for media points
          iconAnchor: IconAnchor.CENTER,
          textField: markerIcon,
          textSize: 16,
          textColor: 0xFFFFFFFF,
          textHaloColor: haloColor,
          textHaloWidth: 5.0,
          textOffset: [0.0, -2.0],
        ),
      );
      _currentMarkerIds.add(markerId);
      print('Added media track point marker $markerId for ${trackPoint.id}');
    } catch (e) {
      print('Error creating media track point marker $markerId: $e');
    }
  }

  /// Add ALL track point markers for debugging (use sparingly)
  Future<void> addAllTrackPointMarkers(Trip trip, List<TrackPoint> trackPoints, int color) async {
    if (trackPoints.isEmpty) return;
    
    final pointManager = await _mapboxMap.annotations.createPointAnnotationManager();
    print('Adding ALL track point markers for trip ${trip.id}: ${trackPoints.length} points');
    
    int markersAdded = 0;
    
    for (int i = 0; i < trackPoints.length; i++) {
      final trackPoint = trackPoints[i];
      
      final markerId = 'trip_${trip.id}_all_$i';
      try {
        // Enhanced debug markers with different styles
        String markerIcon;
        double markerSize;
        double textSize;
        int haloColor;
        double haloWidth;
        
        // Different styles based on position
        if (i == 0) {
          markerIcon = '🚀'; // Start marker
          markerSize = 1.5;
          textSize = 14;
          haloColor = 0xFF4CAF50; // Green
          haloWidth = 4.0;
        } else if (i == trackPoints.length - 1) {
          markerIcon = '🏁'; // End marker
          markerSize = 1.5;
          textSize = 14;
          haloColor = 0xFFF44336; // Red
          haloWidth = 4.0;
        } else if (i % 20 == 0) {
          markerIcon = '⭐'; // Star for every 20th point
          markerSize = 1.2;
          textSize = 12;
          haloColor = 0xFFFF9800; // Orange
          haloWidth = 3.0;
        } else if (i % 10 == 0) {
          markerIcon = '🔵'; // Blue circle for every 10th point
          markerSize = 1.0;
          textSize = 10;
          haloColor = 0xFF2196F3; // Blue
          haloWidth = 2.5;
        } else if (i % 5 == 0) {
          markerIcon = '🟢'; // Green circle for every 5th point
          markerSize = 0.9;
          textSize = 9;
          haloColor = 0xFF4CAF50; // Green
          haloWidth = 2.0;
        } else {
          markerIcon = '•'; // Small dot for regular points
          markerSize = 0.7;
          textSize = 8;
          haloColor = 0xFF00FF00; // Bright green
          haloWidth = 1.5;
        }
        
        await pointManager.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(trackPoint.longitude, trackPoint.latitude)),
            iconSize: markerSize,
            iconAnchor: IconAnchor.CENTER,
            textField: markerIcon,
            textSize: textSize,
            textColor: 0xFFFFFFFF,
            textHaloColor: haloColor,
            textHaloWidth: haloWidth,
            textOffset: [0.0, -0.5],
          ),
        );
        _currentMarkerIds.add(markerId);
        markersAdded++;
      } catch (e) {
        print('Error creating all track point marker $markerId: $e');
      }
    }
    
    print('Successfully added $markersAdded ALL track point markers for trip ${trip.id}');
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
