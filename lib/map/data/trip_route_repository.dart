import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../trips/data/models/trip.dart';
import '../../trips/data/models/track_point.dart';

/// Repository for fetching trip route data for map visualization
class TripRouteRepository {
  final ApiClient _apiClient;

  TripRouteRepository(this._apiClient);

  /// Map backend trip data to Flutter Trip model
  Trip _mapBackendTripToFlutterTrip(Map<String, dynamic> backendTrip) {
    return Trip(
      id: backendTrip['id'] as String,
      title: backendTrip['title'] as String,
      coverUrl: null, // Backend doesn't provide this
      startDate: DateTime.parse(backendTrip['startedAt'] as String),
      endDate: backendTrip['endedAt'] != null 
          ? DateTime.parse(backendTrip['endedAt'] as String) 
          : null,
      visibility: 'PUBLIC', // Default value
      stats: const TripStats(), // Default empty stats
      createdBy: backendTrip['userEmail'] as String,
      createdAt: DateTime.parse(backendTrip['startedAt'] as String), // Use start date as created date
      description: null, // Backend doesn't provide this
      location: null, // Backend doesn't provide this
      tripType: null, // Backend doesn't provide this
      budgetRange: null, // Backend doesn't provide this
      budget: null, // Backend doesn't provide this
      travelBuddies: null, // Backend doesn't provide this
    );
  }

  /// Fetch all trips for route visualization
  /// Note: This requires the current user ID to fetch trips by user
  Future<List<Trip>> getAllTrips() async {
    try {
      // First get the current user to get their ID
      final userResponse = await _apiClient.get('/users/me');
      if (userResponse.statusCode != 200) {
        throw Exception('Failed to get current user: ${userResponse.statusCode}');
      }
      
      final userData = userResponse.data;
      final userId = userData['id'] as String;
      
      // Now fetch trips for this user
      final response = await _apiClient.get('/trips/user/$userId');
      
      if (response.statusCode == 200) {
        final List<dynamic> tripsData = response.data;
        return tripsData.map((tripJson) => _mapBackendTripToFlutterTrip(tripJson)).toList();
      } else {
        throw Exception('Failed to fetch trips: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trips: $e');
    }
  }

  /// Fetch a specific trip
  Future<Trip> getTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId');
      
      if (response.statusCode == 200) {
        return Trip.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch trip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching trip: $e');
    }
  }

  /// Fetch track points for a specific trip
  Future<List<TrackPoint>> getTripTrackPoints(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/track-points');
      
      if (response.statusCode == 200) {
        final List<dynamic> trackPointsData = response.data;
        return trackPointsData.map((tpJson) => _mapBackendTrackPointToFlutterTrackPoint(tpJson)).toList();
      } else {
        throw Exception('Failed to fetch track points: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching track points: $e');
    }
  }

  /// Map backend track point data to Flutter TrackPoint model
  TrackPoint _mapBackendTrackPointToFlutterTrackPoint(Map<String, dynamic> backendTrackPoint) {
    return TrackPoint(
      id: backendTrackPoint['id'] as int,
      tripId: backendTrackPoint['tripId'] as String,
      timestamp: DateTime.parse(backendTrackPoint['ts'] as String),
      latitude: backendTrackPoint['lat'] as double,
      longitude: backendTrackPoint['lon'] as double,
      accuracyMeters: backendTrackPoint['accuracyM'] as double?,
      speedMps: backendTrackPoint['speedMps'] as double?,
      speedKmh: backendTrackPoint['speedKmh'] as double?,
      locationName: backendTrackPoint['locationName'] as String?,
      isSignificant: backendTrackPoint['isSignificant'] as bool? ?? false,
    );
  }
}
