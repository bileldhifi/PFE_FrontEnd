import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Mapbox configuration for the travel diary app
class MapboxConfig {
  // TODO: Replace with your actual Mapbox PUBLIC token (starts with pk.)
  // Get it from: https://account.mapbox.com/access-tokens/
  // IMPORTANT: Use a PUBLIC token (pk.) for Flutter web, not a SECRET token (sk.)
  // Temporary demo token for testing (replace with your own)
  static const String apiKey = 'pk.eyJ1IjoiYmlsZWxkaGlmaTEyMyIsImEiOiJjbTBud25neWswMnoyMnFyMzk0c2p2eTJoIn0.t4xM5j85qcRocNGpq83lMw';
  
  // Map styles for different trip types
  static const String outdoorStyle = 'mapbox://styles/mapbox/outdoors-v12';
  static const String satelliteStyle = 'mapbox://styles/mapbox/satellite-v9';
  static const String streetsStyle = 'mapbox://styles/mapbox/streets-v12';
  static const String darkStyle = 'mapbox://styles/mapbox/dark-v11';
  
  // Default map style
  static const String defaultStyle = outdoorStyle;
  
  // Map constraints
  static const double minZoom = 1.0;
  static const double maxZoom = 20.0;
  static const double defaultZoom = 10.0;
  
  // Default center (Tunis, Tunisia)
  static const double defaultLatitude = 36.8065;
  static const double defaultLongitude = 10.1815;
  
  // Animation settings
  static const Duration animationDuration = Duration(milliseconds: 1000);
  static const Duration markerAnimationDuration = Duration(milliseconds: 500);
  
  // Marker settings
  static const double markerSize = 1.2;
  static const double markerAnchorX = 0.5;
  static const double markerAnchorY = 1.0;
  
  // Polyline settings
  static const double polylineWidth = 6.0;
  static const double polylineOpacity = 0.8;
  
  // Location settings
  static const double locationAccuracyThreshold = 10.0; // meters
  static const Duration locationUpdateInterval = Duration(seconds: 5);
  
  /// Initialize Mapbox with the access token
  static void initialize() {
    MapboxOptions.setAccessToken(apiKey);
  }
}