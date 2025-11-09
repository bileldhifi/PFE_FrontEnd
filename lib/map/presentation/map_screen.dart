import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/env/mapbox_config.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/network/api_client.dart';
import '../data/trip_route_repository.dart';
import '../presentation/controllers/map_trip_controller.dart';
import '../../auth/data/repo/auth_repository.dart';
import '../../post/data/repositories/post_repository.dart';
import '../../post/data/models/post.dart';
import 'utils/marker_image_utils.dart';

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
  bool _showDiscover = false;
  final PostRepository _publicPostRepository = PostRepository();
  final List<_PublicMarker> _publicPostMarkers = [];
  bool _isLoadingPublicPosts = false;
  
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
    _clearPublicMarkers();
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
    if (_showDiscover) {
      _loadPublicPostsMarkers();
    } else {
      _loadTripRoutes();
    }
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

  Future<void> _onViewModeChanged(bool discover) async {
    if (_showDiscover == discover) return;

    setState(() {
      _showDiscover = discover;
      _showTripRoutes = !discover;
    });

    await _tripController?.clearAllAnnotations();
    await _clearPublicMarkers();

    if (discover) {
      await _loadPublicPostsMarkers();
    } else {
      await _loadTripRoutes();
    }
  }

  Future<void> _loadPublicPostsMarkers() async {
    if (_mapboxMap == null) return;

    setState(() {
      _isLoadingPublicPosts = true;
    });

    try {
      await _clearPublicMarkers();
      final posts = await _publicPostRepository.getPublicPosts(limit: 200);
      for (final post in posts) {
        await _addPublicPostMarker(post);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load discover posts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingPublicPosts = false;
      });
    }
  }

  Future<void> _addPublicPostMarker(Post post) async {
    if (_mapboxMap == null) return;
    if (post.latitude == null || post.longitude == null) return;
    if (post.media.isEmpty) return;

    final imageUrl = _resolveImageUrl(post.media.first.url);
    final trackPointId = post.trackPointId;
    final locationName = post.city ?? post.country ?? 'Unknown location';

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return;
      }

      final imageBytes = await createCircularImageWithBorder(
        response.bodyBytes,
        size: 80,
        borderWidth: 6,
      );

      final imageId = 'discover_marker_${post.id}';
      final mbxImage = MbxImage(
        width: 80,
        height: 80,
        data: imageBytes,
      );

      await _mapboxMap!.style.addStyleImage(
        imageId,
        1.0,
        mbxImage,
        false,
        [],
        [],
        null,
      );

      final manager =
          await _mapboxMap!.annotations.createPointAnnotationManager();

      await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              post.longitude!,
              post.latitude!,
            ),
          ),
          iconImage: imageId,
          iconSize: 0.9,
          iconAnchor: IconAnchor.CENTER,
        ),
      );

      manager.addOnPointAnnotationClickListener(
        _PublicPostMarkerClickListener(
          postId: post.id,
          trackPointId: trackPointId,
          locationName: locationName,
          onTap: _handlePublicPostTap,
        ),
      );

      _publicPostMarkers.add(
        _PublicMarker(
          manager: manager,
          imageId: imageId,
          postId: post.id,
          trackPointId: trackPointId,
          locationName: locationName,
        ),
      );
    } catch (e) {
      print('Error adding public post marker: $e');
    }
  }

  Future<void> _clearPublicMarkers() async {
    if (_mapboxMap == null) return;

    for (final marker in _publicPostMarkers) {
      try {
        await _mapboxMap!.annotations.removeAnnotationManager(marker.manager);
      } catch (_) {}
      try {
        await _mapboxMap!.style.removeStyleImage(marker.imageId);
      } catch (_) {}
    }
    _publicPostMarkers.clear();
  }

  void _handlePublicPostTap(String postId, int? trackPointId, String locationName) {
    if (!mounted) return;
    if (trackPointId != null) {
      _onMarkerTap(trackPointId, locationName);
    } else {
      context.push('/posts/$postId');
    }
  }

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return '${ApiClient.baseUrl}$url';
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
    final safeTop = MediaQuery.of(context).padding.top;
    final toggleTop = safeTop + 96;
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
          
          if (_isMapReady && !_isLoading && _error == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _MapHeader(
                styleName: _getMapStyleName(_currentMapStyle),
                onBack: () => context.pop(),
              ),
            ),

          if (_isMapReady && !_isLoading && _error == null)
            Positioned(
  top: toggleTop,
  right: 20,
  child: StylizedButtonColumn(
    showDiscover: _showDiscover,
    onModeChanged: _onViewModeChanged,
    onCreatePost: _showDiscover ? null : _onCreatePostPressed,
    onSettings: () => _showMapSettings(context),
    onLocation: _onLocationPressed,
  ),
),


          if (_showDiscover && _isLoadingPublicPosts)
            Positioned(
              top: toggleTop + 150,
              right: 20,
              child: const SizedBox(
                width: 64,
                child: LinearProgressIndicator(),
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









class _PublicMarker {
  final PointAnnotationManager manager;
  final String imageId;
  final String postId;
  final int? trackPointId;
  final String locationName;

  _PublicMarker({
    required this.manager,
    required this.imageId,
    required this.postId,
    required this.trackPointId,
    required this.locationName,
  });
}

class _PublicPostMarkerClickListener extends OnPointAnnotationClickListener {
  final String postId;
  final int? trackPointId;
  final String locationName;
  final void Function(String postId, int? trackPointId, String locationName) onTap;

  _PublicPostMarkerClickListener({
    required this.postId,
    required this.trackPointId,
    required this.locationName,
    required this.onTap,
  });

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onTap(postId, trackPointId, locationName);
  }
}

class _MapHeader extends StatelessWidget {
  final String styleName;
  final VoidCallback onBack;

  const _MapHeader({
    required this.styleName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(
        top: top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TopBarButton(
                icon: Icons.arrow_back,
                onPressed: onBack,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: _FrostedPill(
                borderRadius: 20,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                child: const Text(
                  'Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.25,
                    shadows: [
                      Shadow(
                        color: Colors.black38,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _FrostedPill(
                borderRadius: 18,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                child: Text(
                  styleName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical segmented toggle with sliding thumb.
class VerticalSegmentedToggle extends StatelessWidget {
  final bool discover;
  final ValueChanged<bool> onChanged;
  final double width;
  final double segmentHeight;

  const VerticalSegmentedToggle({
    required this.discover,
    required this.onChanged,
    this.width = 48,
    this.segmentHeight = 48,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return _FrostedPill(
      borderRadius: 24,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleSegment(
            icon: Icons.person_pin_circle,
            active: !discover,
            activeColor: primary,
            onTap: () => onChanged(false),
          ),
          const SizedBox(height: 10),
          _ToggleSegment(
            icon: Icons.public,
            active: discover,
            activeColor: primary,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

/// Updated column of right-side controls that uses the sliding toggle.
/// Accepts callbacks for mode change, create post, settings and location.
class StylizedButtonColumn extends StatelessWidget {
  final bool showDiscover;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback? onCreatePost;
  final VoidCallback? onSettings;
  final VoidCallback? onLocation;

  const StylizedButtonColumn({
    required this.showDiscover,
    required this.onModeChanged,
    this.onCreatePost,
    this.onSettings,
    this.onLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (onSettings != null) {
      children.addAll([
        _TopBarButton(
          icon: Icons.settings,
          onPressed: onSettings!,
        ),
        const SizedBox(height: 12),
      ]);
    }

    children.addAll([
      VerticalSegmentedToggle(
        discover: showDiscover,
        onChanged: onModeChanged,
      ),
    ]);

    if (onCreatePost != null) {
      children.addAll([
        const SizedBox(height: 12),
        _TopBarButton(
          icon: Icons.add_a_photo_rounded,
          onPressed: onCreatePost!,
        ),
      ]);
    }

    if (onLocation != null) {
      children.addAll([
        const SizedBox(height: 12),
        _TopBarButton(
          icon: Icons.my_location,
          onPressed: onLocation!,
        ),
      ]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

/// Top small circular button used for settings/back.
/// Now includes optional label below the icon for clarity.
class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;

  const _TopBarButton({
    required this.icon,
    required this.onPressed,
    this.label,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FrostedPill(
          borderRadius: 23,
          width: 46,
          height: 46,
          child: IconButton(
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              splashFactory: NoSplash.splashFactory,
              backgroundColor: Colors.transparent,
            ),
            icon: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(
            label!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleSegment({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? Colors.white.withOpacity(0.24) : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: active ? 2.2 : 1.5),
            boxShadow: [
              BoxShadow(
                color: active
                    ? activeColor.withOpacity(0.35)
                    : Colors.black.withOpacity(0.2),
                blurRadius: active ? 16 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _FrostedPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double? width;
  final double? height;

  const _FrostedPill({
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.width,
    this.height,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.55), width: 1.5),
      ),
      child: child,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: container,
        ),
      ),
    );
  }
}

