import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import '../../core/env/mapbox_config.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/network/api_client.dart';
import '../data/trip_route_repository.dart';
import '../presentation/controllers/map_trip_controller.dart';
import '../../auth/data/repo/auth_repository.dart';

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
  
  // Trip route management
  MapTripController? _tripController;
  bool _showTripRoutes = false; // Start with routes hidden by default
  
  // Authentication
  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _tripController?.clearAllAnnotations();
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
    
    // Initialize trip route controller
    final apiClient = ApiClient();
    final tripRouteRepository = TripRouteRepository(apiClient);
    _tripController = MapTripController(
      mapboxMap: mapboxMap,
      tripRouteRepository: tripRouteRepository,
    );
    
    setState(() {
      _isMapReady = true;
    });
    
    // Don't automatically load trip routes - let user toggle them manually
    // This prevents 403 errors on map load
  }

  /// Load trip routes on the map
  Future<void> _loadTripRoutes() async {
    if (_tripController != null && _showTripRoutes) {
      try {
        // Check if user is authenticated first
        final isAuthenticated = await _authRepository.isAuthenticated();
        
        if (!isAuthenticated) {
          // Don't show error, just don't load routes
          print('User not authenticated - skipping trip routes');
          return;
        }
        
        // Validate token by trying to get current user first
        // This will catch expired/invalid tokens before making the trips API call
        try {
          await _authRepository.getCurrentUser();
        } catch (e) {
          print('Token validation failed - skipping trip routes: $e');
          return;
        }
        
        // Only proceed if token validation succeeded
        await _tripController!.loadAndDisplayTripRoutes();
      } catch (e) {
        print('Error loading trip routes: $e');
        
        // Handle all errors gracefully - don't show any error to user
        // Just log and continue with map functionality
        if (e.toString().contains('403') || e.toString().contains('401')) {
          print('Authentication error - skipping trip routes');
        } else {
          print('Failed to load trip routes: $e');
        }
        
        // Don't set any error state - just continue with map
        return;
      }
    }
  }

  /// Toggle trip routes visibility
  Future<void> _toggleTripRoutes() async {
    // Check authentication first
    final isAuthenticated = await _authRepository.isAuthenticated();
    
    if (!isAuthenticated) {
      // Show a snackbar message instead of toggling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to view your trip routes'),
            action: SnackBarAction(
              label: 'Login',
              onPressed: () => context.go('/auth/login'),
            ),
          ),
        );
      }
      return;
    }
    
    if (!_showTripRoutes) {
      // User wants to show routes - validate token first
      try {
        await _authRepository.getCurrentUser();
      } catch (e) {
        print('Token validation failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Session expired. Please log in again.'),
              action: SnackBarAction(
                label: 'Login',
                onPressed: () => context.go('/auth/login'),
              ),
            ),
          );
        }
        return;
      }
    }
    
    setState(() {
      _showTripRoutes = !_showTripRoutes;
    });
    
    if (_showTripRoutes) {
      // Try to load routes
      try {
        await _loadTripRoutes();
      } catch (e) {
        print('Failed to load trip routes: $e');
        // If loading fails, just toggle back to off state
        setState(() {
          _showTripRoutes = false;
        });
        
        // Show a subtle message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load trip routes. Please try again later.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      // Clear trip routes
      if (_tripController != null) {
        await _tripController!.clearAllAnnotations();
      }
    }
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
            // Trip routes toggle
            FutureBuilder<bool>(
              future: _authRepository.isAuthenticated(),
              builder: (context, snapshot) {
                final isAuthenticated = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isAuthenticated 
                        ? (_showTripRoutes ? Icons.route : Icons.route_outlined)
                        : Icons.route_outlined,
                    color: isAuthenticated 
                        ? (_showTripRoutes ? Colors.blue : Colors.grey)
                        : Colors.grey,
                  ),
                  onPressed: _toggleTripRoutes,
                  tooltip: isAuthenticated 
                      ? (_showTripRoutes ? 'Hide Trip Routes' : 'Show Trip Routes')
                      : 'Login to view trip routes',
                );
              },
            ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppErrorWidget(
                    message: _error!,
                    onRetry: () {
                      setState(() {
                        _error = null;
                        _isLoading = true;
                      });
                      _initializeMap();
                    },
                  ),
                  if (_error!.contains('log in'))
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () => context.go('/auth/login'),
                        child: const Text('Go to Login'),
                      ),
                    ),
                ],
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