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
  bool _showTripRoutes = true; // Always show routes by default
  String _trackPointDensity = 'high'; // High density by default for better visibility
  
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

  final apiClient = ApiClient();
  final tripRouteRepository = TripRouteRepository(apiClient);
  _tripController = MapTripController(
    mapboxMap: mapboxMap,
    tripRouteRepository: tripRouteRepository,
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // do nothing if this route isn’t on top anymore
    final route = ModalRoute.of(context);
    if (!mounted || route == null || !route.isCurrent) return;

    setState(() => _isMapReady = true);
    _loadTripRoutes();
  });
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
        
        // Load trips with custom density
        await _loadTripsWithDensity();
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

  /// Load trips with custom track point density
  Future<void> _loadTripsWithDensity() async {
    try {
      // Use the existing method to load routes
      await _tripController!.loadAndDisplayTripRoutes();
      
      // The track points will be loaded with the enhanced density from the controller
      print('Loaded trips with density: $_trackPointDensity');
    } catch (e) {
      print('Error loading trips with density: $e');
      rethrow;
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

  /// Change track point density
  Future<void> _changeTrackPointDensity(String density) async {
    setState(() {
      _trackPointDensity = density;
    });
    
    // Reload trip routes with new density
    if (_showTripRoutes && _tripController != null) {
      await _loadTripRoutes();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Track point density changed to: $density')),
    );
  }

  /// Debug method to show all track points
  Future<void> _debugTrackPoints() async {
    if (_tripController == null) return;
    
    try {
      // Check authentication first
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (!isAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to debug track points')),
        );
        return;
      }
      
      // Clear existing annotations
      await _tripController!.clearAllAnnotations();
      
      // Load trips and show all track points
      final apiClient = ApiClient();
      final tripRouteRepository = TripRouteRepository(apiClient);
      final trips = await tripRouteRepository.getAllTrips();
      
      print('Debug: Found ${trips.length} trips');
      
      for (int i = 0; i < trips.length; i++) {
        final trip = trips[i];
        print('Debug: Processing trip ${trip.title}');
        
        final trackPoints = await tripRouteRepository.getTripTrackPoints(trip.id);
        print('Debug: Trip ${trip.title} has ${trackPoints.length} track points');
        
        if (trackPoints.isNotEmpty) {
          // Use a default color for debug markers
          const color = 0xFF00FF00; // Green
          await _tripController!.addAllTrackPointMarkers(trip, trackPoints, color);
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug: Showing all track points for ${trips.length} trips')),
      );
    } catch (e) {
      print('Debug error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug error: $e')),
      );
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
          // Track point density selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.density_medium),
            onSelected: _changeTrackPointDensity,
            tooltip: 'Track Point Density',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'high',
                child: Row(
                  children: [
                    Icon(Icons.density_medium, color: Colors.green),
                    SizedBox(width: 8),
                    Text('High Density'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'medium',
                child: Row(
                  children: [
                    Icon(Icons.density_medium, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Medium Density'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'low',
                child: Row(
                  children: [
                    Icon(Icons.density_medium, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Low Density'),
                  ],
                ),
              ),
            ],
          ),
          // Debug button for track points
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugTrackPoints,
            tooltip: 'Debug Track Points',
          ),
          // Trip routes info (always visible)
          FutureBuilder<bool>(
            future: _authRepository.isAuthenticated(),
            builder: (context, snapshot) {
              final isAuthenticated = snapshot.data ?? false;
              return IconButton(
                icon: Icon(
                  isAuthenticated ? Icons.route : Icons.route_outlined,
                  color: isAuthenticated ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAuthenticated 
                            ? 'Trip routes are always visible'
                            : 'Please log in to view trip routes',
                      ),
                    ),
                  );
                },
                tooltip: isAuthenticated 
                    ? 'Trip routes are always visible'
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        _initializeMap();
                      });
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
          
          // Location button - keep in stack
          if (_isMapReady && !_isLoading && _error == null)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'location_btn', // Unique hero tag
                onPressed: _onLocationPressed,
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
            
          // Map style indicator
          if (_isMapReady && !_isLoading && _error == null)
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
      ),
      // Use Scaffold's floatingActionButton instead of Positioned in Stack
      floatingActionButton: (_isMapReady && !_isLoading && _error == null)
          ? FloatingActionButton.extended(
              heroTag: 'create_post_btn', // Unique hero tag
              onPressed: () => _onCreatePostPressed(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Create Post'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Handle create post button press - pass cached data
  /// Includes trips with their IDs for post creation
  void _onCreatePostPressed() {
    final trips = _tripController?.trips ?? [];
    
    context.push(
      '/post/select-location',
      extra: {
        'currentLocation': _currentLocation,
        'trips': trips,
        'trackPoints': _tripController?.trackPoints ?? {},
      },
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