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
  )
    ..onMarkerTap = _onMarkerTap;

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
            
            // Custom Top Bar (inspired by Snapchat map style)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _CustomMapTopBar(
                onBackPressed: () => context.pop(),
                onSettingsPressed: () => _showMapSettings(context),
              ),
            ),
            
            // Create Post Button - center bottom position
            if (_isMapReady && !_isLoading && _error == null)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: _CreatePostButton(
                    onPressed: () => _onCreatePostPressed(),
                  ),
                ),
              ),
        ],
      ),
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

  /// Handle marker tap - open media viewer (Snapchat style)
  void _onMarkerTap(int trackPointId, String locationName) {
    context.push(
      '/post/media/$trackPointId?location=$locationName',
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
  
  /// Show map settings bottom sheet
  void _showMapSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Map Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Map Style
            ListTile(
              leading: const Icon(Icons.layers),
              title: const Text('Map Style'),
              subtitle: Text(_getMapStyleName(_currentMapStyle)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildMapStylePicker(),
                );
              },
            ),
            
            // Track Point Density
            ListTile(
              leading: const Icon(Icons.density_medium),
              title: const Text('Track Point Density'),
              subtitle: Text(_trackPointDensity.toUpperCase()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  builder: (context) => _buildDensityPicker(),
                );
              },
            ),
            
            // Debug Track Points
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Track Points'),
              subtitle: const Text('Show all track points'),
              onTap: () {
                Navigator.pop(context);
                _debugTrackPoints();
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  /// Build map style picker
  Widget _buildMapStylePicker() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Map Style',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildStyleOption('Outdoor', MapboxConfig.outdoorStyle, Icons.terrain),
          _buildStyleOption('Satellite', MapboxConfig.satelliteStyle, Icons.satellite),
          _buildStyleOption('Streets', MapboxConfig.streetsStyle, Icons.map),
          _buildStyleOption('Dark', MapboxConfig.darkStyle, Icons.dark_mode),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  /// Build density picker
  Widget _buildDensityPicker() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Track Point Density',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildDensityOption('High', 'high', Colors.green),
          _buildDensityOption('Medium', 'medium', Colors.orange),
          _buildDensityOption('Low', 'low', Colors.red),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  /// Build style option
  Widget _buildStyleOption(String label, String value, IconData icon) {
    final isSelected = _currentMapStyle == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey),
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
      onTap: () {
        Navigator.pop(context);
        _changeMapStyle(value);
      },
    );
  }
  
  /// Build density option
  Widget _buildDensityOption(String label, String value, Color color) {
    final isSelected = _trackPointDensity == value;
    return ListTile(
      leading: Icon(Icons.density_medium, color: isSelected ? color : Colors.grey),
      title: Text(label),
      trailing: isSelected ? Icon(Icons.check, color: color) : null,
      onTap: () {
        Navigator.pop(context);
        _changeTrackPointDensity(value);
      },
    );
  }
}

/// Custom top bar for map screen (Snapchat-inspired)
class _CustomMapTopBar extends StatelessWidget {
  final VoidCallback onBackPressed;
  final VoidCallback onSettingsPressed;

  const _CustomMapTopBar({
    required this.onBackPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.4),
            Colors.black.withOpacity(0.2),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 0.8, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Back button (left)
          _TopBarButton(
            icon: Icons.arrow_back,
            onPressed: onBackPressed,
          ),
          
          // Title (center)
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Settings button (right)
          _TopBarButton(
            icon: Icons.settings,
            onPressed: onSettingsPressed,
          ),
        ],
      ),
    );
  }
}

/// Top bar button widget
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _TopBarButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        color: Colors.white,
        iconSize: 22,
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

/// Create Post Button - Modern floating design
class _CreatePostButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreatePostButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade600,
              Colors.purple.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_a_photo_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Create Post',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}