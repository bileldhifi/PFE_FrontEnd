import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../core/env/mapbox_config.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';

/// Main map screen for displaying trip routes and locations
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  bool _isMapReady = false;
  String _currentMapStyle = MapboxConfig.defaultStyle;
  geo.Position? _currentLocation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapboxMap?.dispose();
    super.dispose();
  }

  /// Initialize the map
  Future<void> _initializeMap() async {
    try {
      // Check location permissions
      await _checkLocationPermissions();
      
      // Get current location if available
      await _getCurrentLocation();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to initialize map: $e';
        });
      }
    }
  }

  /// Check and request location permissions
  Future<void> _checkLocationPermissions() async {
    try {
      final permission = await geo.Geolocator.checkPermission();
      
      if (permission == geo.LocationPermission.denied) {
        final requestPermission = await geo.Geolocator.requestPermission();
        if (requestPermission == geo.LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == geo.LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }
    } catch (e) {
      // Permission error, but continue without location
      print('Location permission error: $e');
    }
  }

  /// Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = position;
        });
      }
    } catch (e) {
      // Location not available, use default center
      print('Could not get current location: $e');
    }
  }

  /// Handle map creation
  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    setState(() {
      _isMapReady = true;
    });
  }

  /// Handle map style change
  void _changeMapStyle(String style) {
    setState(() {
      _currentMapStyle = style;
    });
  }

  /// Handle location button press
  Future<void> _onLocationPressed() async {
    await _getCurrentLocation();
    
    if (_currentLocation != null && _mapboxMap != null) {
      final position = _currentLocation!;
      final cameraOptions = CameraOptions(
        center: Point(coordinates: Position(position.longitude, position.latitude)),
        zoom: 15.0,
      );
      
      await _mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Map style selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.layers),
            onSelected: _changeMapStyle,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MapboxConfig.outdoorStyle,
                child: Text('Outdoor'),
              ),
              const PopupMenuItem(
                value: MapboxConfig.satelliteStyle,
                child: Text('Satellite'),
              ),
              const PopupMenuItem(
                value: MapboxConfig.streetsStyle,
                child: Text('Streets'),
              ),
              const PopupMenuItem(
                value: MapboxConfig.darkStyle,
                child: Text('Dark'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          if (_isLoading)
            const Center(child: LoadingWidget())
          else if (_error != null)
            Center(
              child: AppErrorWidget(
                message: _error!,
                onRetry: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _initializeMap();
                },
              ),
            )
          else
            MapWidget(
              key: ValueKey("mapWidget_$_currentMapStyle"),
              cameraOptions: CameraOptions(
                center: _currentLocation != null
                    ? Point(coordinates: Position(
                        _currentLocation!.longitude,
                        _currentLocation!.latitude,
                      ))
                    : Point(coordinates: Position(
                        MapboxConfig.defaultLongitude,
                        MapboxConfig.defaultLatitude,
                      )),
                zoom: MapboxConfig.defaultZoom,
              ),
              onMapCreated: _onMapCreated,
            ),
          
          // Floating action buttons
          if (_isMapReady && !_isLoading && _error == null) ...[
            // Location button
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _onLocationPressed,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
            
            // Map style indicator
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _getMapStyleName(_currentMapStyle),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get human-readable map style name
  String _getMapStyleName(String style) {
    switch (style) {
      case MapboxConfig.outdoorStyle:
        return 'Outdoor';
      case MapboxConfig.satelliteStyle:
        return 'Satellite';
      case MapboxConfig.streetsStyle:
        return 'Streets';
      case MapboxConfig.darkStyle:
        return 'Dark';
      default:
        return 'Map';
    }
  }
}