import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/trips/data/dtos/track_point_request.dart';
import 'package:travel_diary_frontend/trips/data/dtos/track_point_response.dart';
import 'package:travel_diary_frontend/trips/data/models/track_point.dart';

/// Repository for TrackPoint operations
/// Handles all API calls related to location tracking
class TrackPointRepository {
  final ApiClient _apiClient;

  TrackPointRepository({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  /// Add a single track point to a trip
  Future<TrackPointResponse?> addTrackPoint(String tripId, TrackPointRequest request) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/track-points',
        data: request.toJson(),
      );
      
      // Handle case where track point was skipped due to optimization
      if (response.statusCode == 200 && (response.data == null || response.data == '')) {
        return null; // Point was skipped
      }
      
      // Handle case where response.data might be a string instead of Map
      if (response.data is String) {
        throw Exception('Unexpected string response from server: ${response.data}');
      }
      
      return TrackPointResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to add track point: $e');
    }
  }

  /// Add multiple track points in bulk
  Future<List<TrackPointResponse>> addTrackPointsBulk(
      String tripId, 
      List<TrackPointRequest> requests) async {
    try {
      final response = await _apiClient.post(
        '/trips/$tripId/track-points/bulk',
        data: requests.map((r) => r.toJson()).toList(),
      );
      
      final List<dynamic> data = response.data;
      return data.map((json) => TrackPointResponse.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to add track points in bulk: $e');
    }
  }

  /// Get all track points for a trip
  Future<List<TrackPointResponse>> getTrackPoints(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/track-points');
      final List<dynamic> data = response.data;
      return data.map((json) => TrackPointResponse.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get track points: $e');
    }
  }

  /// Get track points within a time range
  Future<List<TrackPointResponse>> getTrackPointsByTimeRange(
      String tripId, 
      DateTime startTime, 
      DateTime endTime) async {
    try {
      final response = await _apiClient.get(
        '/trips/$tripId/track-points',
        queryParameters: {
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        },
      );
      
      final List<dynamic> data = response.data;
      return data.map((json) => TrackPointResponse.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get track points by time range: $e');
    }
  }

  /// Get track points near a specific location
  Future<List<TrackPointResponse>> getTrackPointsNearLocation(
      String tripId, 
      double latitude, 
      double longitude, 
      double radiusMeters) async {
    try {
      final response = await _apiClient.get(
        '/trips/$tripId/track-points',
        queryParameters: {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'radius': radiusMeters.toString(),
        },
      );
      
      final List<dynamic> data = response.data;
      return data.map((json) => TrackPointResponse.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get track points near location: $e');
    }
  }

  /// Get the latest track point for a trip
  Future<TrackPointResponse?> getLatestTrackPoint(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/track-points/latest');
      
      if (response.statusCode == 404) {
        return null; // No track points found
      }
      
      return TrackPointResponse.fromJson(response.data);
    } catch (e) {
      if (e.toString().contains('404')) {
        return null; // No track points found
      }
      throw Exception('Failed to get latest track point: $e');
    }
  }

  /// Calculate total distance for a trip
  Future<double> getTotalDistance(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId/track-points/distance');
      return (response.data as num).toDouble();
    } catch (e) {
      throw Exception('Failed to calculate total distance: $e');
    }
  }

  /// Delete a specific track point
  Future<void> deleteTrackPoint(String tripId, int trackPointId) async {
    try {
      await _apiClient.delete('/trips/$tripId/track-points/$trackPointId');
    } catch (e) {
      throw Exception('Failed to delete track point: $e');
    }
  }

  /// Convert TrackPointResponse to TrackPoint model
  TrackPoint mapToTrackPoint(TrackPointResponse response) {
    return response.toTrackPoint();
  }

  /// Convert list of TrackPointResponse to list of TrackPoint models
  List<TrackPoint> mapToTrackPoints(List<TrackPointResponse> responses) {
    return responses.map((response) => mapToTrackPoint(response)).toList();
  }

  /// Create TrackPointRequest from current location
  TrackPointRequest createTrackPointRequest({
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    double? speedMps,
  }) {
    return TrackPointRequest(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      speedMps: speedMps,
    );
  }

  /// Validate track point data before sending
  bool validateTrackPoint(TrackPointRequest request) {
    return request.latitude >= -90.0 && 
           request.latitude <= 90.0 && 
           request.longitude >= -180.0 && 
           request.longitude <= 180.0 &&
           (request.accuracyMeters == null || request.accuracyMeters! >= 0) &&
           (request.speedMps == null || request.speedMps! >= 0);
  }
}
