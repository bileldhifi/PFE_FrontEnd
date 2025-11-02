import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../data/trip_route_repository.dart';
import '../../../trips/data/models/trip.dart';
import '../../../trips/data/models/track_point.dart';
import '../../../post/data/repositories/post_repository.dart';

/// Controller for managing trip route visualization on the map
class MapTripController {
  final MapboxMap _mapboxMap;
  final TripRouteRepository _tripRouteRepository;
  final PostRepository _postRepository = PostRepository();
  
  // Track current annotations for cleanup
  final List<PolylineAnnotationManager> _currentPolylines = [];
  final List<dynamic> _currentMarkers = []; // Can hold both Point and Circle managers
  
  // Cache loaded data for reuse (optimization - avoid duplicate API calls)
  List<Trip> trips = [];
  Map<String, List<TrackPoint>> trackPoints = {};
  
  // Track which track points have media
  final Set<int> _trackPointsWithMedia = {};
  
  // Callback for marker clicks
  Function(int trackPointId, String locationName)? onMarkerTap;
  
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
      
      // Check which track points have media and show markers
      await _checkTrackPointsForMedia();
    } catch (e) {
      print('Error loading trip routes: $e');
      rethrow;
    }
  }
  
  /// Check which track points have posts/media
  Future<void> _checkTrackPointsForMedia() async {
    try {
      _trackPointsWithMedia.clear();
      
      for (final trip in trips) {
        final points = trackPoints[trip.id] ?? [];
        
        for (final point in points) {
          try {
            final posts = await _postRepository.getPostsByTrackPoint(
              point.id.toString(),
            );
            
            if (posts.isNotEmpty) {
              _trackPointsWithMedia.add(point.id);
              print('Track point ${point.id} has ${posts.length} posts');
            }
          } catch (e) {
            // Silently continue if error checking this track point
            print('Error checking media for track point ${point.id}');
          }
        }
      }
      
      // Redraw markers with media indicators
      await _redrawMarkersWithMedia();
    } catch (e) {
      print('Error checking track points for media: $e');
    }
  }
  
  /// Redraw markers to show media indicators
  Future<void> _redrawMarkersWithMedia() async {
    try {
      // Clear existing markers
      for (final marker in _currentMarkers) {
        try {
          await _mapboxMap.annotations.removeAnnotationManager(marker);
        } catch (e) {
          // Ignore if already removed
        }
      }
      _currentMarkers.clear();
      
      // Redraw all track points with media indicators
      for (final trip in trips) {
        final points = trackPoints[trip.id] ?? [];
        
        for (int i = 0; i < points.length; i++) {
          final point = points[i];
          final hasMedia = _trackPointsWithMedia.contains(point.id);
          
          if (hasMedia) {
            // Show camera icon for points with media
            await _addMediaMarker(point);
          }
        }
      }
    } catch (e) {
      print('Error redrawing markers with media: $e');
    }
  }
  
  /// Add a media marker for track point using image from post (Snapchat style)
  Future<void> _addMediaMarker(TrackPoint trackPoint) async {
    try {
      print('Adding IMAGE media marker for track point ${trackPoint.id} at ${trackPoint.latitude}, ${trackPoint.longitude}');
      
      // Fetch posts for this track point to get the first image
      final posts = await _postRepository.getPostsByTrackPoint(trackPoint.id.toString());
      
      if (posts.isEmpty || posts.first.media.isEmpty) {
        print('No media found for track point ${trackPoint.id}');
        return;
      }
      
      final firstMediaUrl = 'http://localhost:8089/app-backend${posts.first.media.first.url}';
      print('Loading image from: $firstMediaUrl');
      
      // Download the image
      final response = await http.get(Uri.parse(firstMediaUrl));
      if (response.statusCode != 200) {
        print('Failed to load image: ${response.statusCode}');
        return;
      }
      
      // Create a circular image with border (smaller size for better map appearance)
      final imageBytes = await _createCircularImageWithBorder(
        response.bodyBytes,
        size: 80,
        borderWidth: 6,
      );
      
      // Add image to map style with unique ID
      final imageId = 'media_marker_${trackPoint.id}';
      
      // Create MbxImage from bytes
      final mbxImage = MbxImage(
        width: 80,
        height: 80,
        data: imageBytes,
      );
      
      await _mapboxMap.style.addStyleImage(
        imageId,
        1.0, // scale
        mbxImage,
        false, // sdf
        [], // stretchX
        [], // stretchY
        null, // content
      );
      
      // Create point annotation with the image
      final pointManager = 
          await _mapboxMap.annotations.createPointAnnotationManager();
      
      final annotation = await pointManager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              trackPoint.longitude,
              trackPoint.latitude,
            ),
          ),
          iconImage: imageId,
          iconSize: 0.9, // Slightly smaller for better visibility
          iconAnchor: IconAnchor.CENTER,
        ),
      );
      
      print('Created image media marker: $annotation');
      
      // Store manager for cleanup
      _currentMarkers.add(pointManager);
      
      // Add click listener for the media marker
      pointManager.addOnPointAnnotationClickListener(
        ImageMarkerClickListener(
          trackPointId: trackPoint.id,
          locationName: trackPoint.locationName ?? 'Track Point',
          onTap: onMarkerTap,
        ),
      );
      
      print('Added click listener for image marker at track point ${trackPoint.id}');
    } catch (e) {
      print('Error adding image media marker: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }
  
  /// Create a circular image with white border (like Snapchat)
  Future<Uint8List> _createCircularImageWithBorder(
    Uint8List imageBytes, {
    required int size,
    required int borderWidth,
  }) async {
    // Decode the image
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image sourceImage = frameInfo.image;
    
    // Create a canvas to draw on
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final paint = ui.Paint();
    
    final double radius = size / 2.0;
    final double center = radius;
    
    // Draw outer white border circle
    final borderPaint = ui.Paint()
      ..color = const ui.Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;
    canvas.drawCircle(
      ui.Offset(center, center),
      radius,
      borderPaint,
    );
    
    // Draw inner circle with image
    final innerRadius = radius - borderWidth;
    canvas.save();
    canvas.clipPath(
      ui.Path()..addOval(
        ui.Rect.fromCircle(
          center: ui.Offset(center, center),
          radius: innerRadius,
        ),
      ),
    );
    
    // Draw the image to fill the circle
    canvas.drawImageRect(
      sourceImage,
      ui.Rect.fromLTWH(
        0,
        0,
        sourceImage.width.toDouble(),
        sourceImage.height.toDouble(),
      ),
      ui.Rect.fromCircle(
        center: ui.Offset(center, center),
        radius: innerRadius,
      ),
      paint,
    );
    
    canvas.restore();
    
    // Add orange accent ring (thinner for smaller markers)
    final accentPaint = ui.Paint()
      ..color = const ui.Color(0xFFFF6B35)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(
      ui.Offset(center, center),
      radius - borderWidth / 2,
      accentPaint,
    );
    
    // Convert to image bytes
    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
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
    
    _currentPolylines.add(polylineManager);
  }

  /// Add enhanced start and end markers for trip
  Future<void> _addTripMarkers(Trip trip, List<TrackPoint> trackPoints, int color) async {
    if (trackPoints.isEmpty) return;

    // SIMPLIFIED: Skip start/end/track point markers for now
    // Focus only on media markers (Snapchat feature)
    print('Skipping start/end markers - will only show media markers');
  }

  /// Add individual track point markers along the route
  Future<void> _addTrackPointMarkers(Trip trip, List<TrackPoint> trackPoints, int color) async {
    // SIMPLIFIED: Skip track point markers for now
    // They will be added only when they have media
    print('Skipping regular track point markers - will only show media markers');
  }

  /// Clear all trip route annotations
  Future<void> clearAllAnnotations() async {
    try {
      // Clear polylines
      for (final polyline in _currentPolylines) {
        try {
          await _mapboxMap.annotations.removeAnnotationManager(polyline);
        } catch (e) {
          // Ignore if already removed
        }
      }
      _currentPolylines.clear();
      
      // Clear markers
      for (final marker in _currentMarkers) {
        try {
          await _mapboxMap.annotations.removeAnnotationManager(marker);
        } catch (e) {
          // Ignore if already removed
        }
      }
      _currentMarkers.clear();
      
      _trackPointsWithMedia.clear();
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
      
      _currentMarkers.add(pointManager);
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
        markersAdded++;
      } catch (e) {
        print('Error creating track point marker $markerId: $e');
      }
    }
    
    // Add the manager once after creating all markers
    if (markersAdded > 0) {
      _currentMarkers.add(pointManager);
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
      
      // Add the manager after creating the media marker
      _currentMarkers.add(pointManager);
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
        markersAdded++;
      } catch (e) {
        print('Error creating all track point marker $markerId: $e');
      }
    }
    
    // Add the manager once after creating all markers
    if (markersAdded > 0) {
      _currentMarkers.add(pointManager);
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

/// Click listener for media markers (circles)
/// Click listener for image media markers (PointAnnotation)
class ImageMarkerClickListener extends OnPointAnnotationClickListener {
  final int trackPointId;
  final String locationName;
  final Function(int trackPointId, String locationName)? onTap;
  
  ImageMarkerClickListener({
    required this.trackPointId,
    required this.locationName,
    this.onTap,
  });
  
  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    print('Image marker clicked: Track point $trackPointId');
    onTap?.call(trackPointId, locationName);
  }
}

/// Legacy click listener for media markers (CircleAnnotation)
class MediaMarkerClickListener extends OnCircleAnnotationClickListener {
  final int trackPointId;
  final String locationName;
  final Function(int trackPointId, String locationName)? onTap;

  MediaMarkerClickListener({
    required this.trackPointId,
    required this.locationName,
    required this.onTap,
  });

  @override
  void onCircleAnnotationClick(CircleAnnotation annotation) {
    print('Media marker clicked: Track point $trackPointId');
    onTap?.call(trackPointId, locationName);
  }
}
