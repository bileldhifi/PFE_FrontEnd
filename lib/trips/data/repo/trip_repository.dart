import 'dart:developer';

import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/trips/data/dtos/trip_request.dart';
import 'package:travel_diary_frontend/trips/data/dtos/trip_response.dart';
import 'package:travel_diary_frontend/trips/data/models/timeline_response.dart';
import 'package:travel_diary_frontend/trips/data/models/trip.dart';
import 'package:travel_diary_frontend/trips/data/repo/trip_local_storage.dart';

class TripRepository {
  final ApiClient _apiClient;

  TripRepository({ApiClient? apiClient}) 
      : _apiClient = apiClient ?? ApiClient();

  /// Start a new trip
  Future<TripResponse> startTrip(String userId, String title) async {
    try {
      final request = TripRequest(title: title);
      final response = await _apiClient.post(
        '/trips/start/$userId',
        data: request.toJson(),
      );
      
      return TripResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to start trip: $e');
    }
  }

  /// Start a new trip with additional details
  Future<TripResponse> startTripWithDetails(String userId, String title, Map<String, dynamic>? additionalDetails) async {
    try {
      final tripResponse = await startTrip(userId, title);
      
      // Save additional details locally if provided
      if (additionalDetails != null) {
        await TripLocalStorage.saveTripDetails(tripResponse.id, additionalDetails);
      }
      
      return tripResponse;
    } catch (e) {
      throw Exception('Failed to start trip with details: $e');
    }
  }

  /// End an existing trip
  Future<TripResponse> endTrip(String tripId) async {
    try {
      final response = await _apiClient.patch('/trips/end/$tripId');
      return TripResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to end trip: $e');
    }
  }

  /// Get all trips for a user
  Future<List<TripResponse>> getTripsByUser(String userId) async {
    try {
      final response = await _apiClient.get('/trips/user/$userId');
      final List<dynamic> data = response.data;
      return data.map((json) => TripResponse.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get trips: $e');
    }
  }

  /// Get a single trip by ID
  Future<TripResponse> getTrip(String tripId) async {
    try {
      final response = await _apiClient.get('/trips/$tripId');
      return TripResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }

  /// Delete a trip
  Future<void> deleteTrip(String tripId) async {
    try {
      await _apiClient.delete('/trips/$tripId');
      // Also remove local storage data
      await TripLocalStorage.removeTripDetails(tripId);
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  /// Convert TripResponse to Trip model
  Future<Trip> mapToTrip(TripResponse response) async {
    // Get additional details from local storage
    final additionalDetails = await TripLocalStorage.getTripDetails(response.id);
    
    return Trip(
      id: response.id,
      title: response.title,
      startDate: response.startedAt,
      endDate: response.endedAt,
      visibility: response.visibility ?? 
                   additionalDetails?['visibility'] ?? 
                   'PUBLIC',
      stats: response.stats ?? const TripStats(), // Use stats from backend
      createdBy: response.userEmail, // Using email as createdBy for now
      createdAt: response.startedAt,
      description: additionalDetails?['description'],
      coverUrl: response.coverUrl ?? additionalDetails?['coverUrl'],
      // Map additional fields from local storage
      location: additionalDetails?['location'],
      tripType: additionalDetails?['tripType'],
      budgetRange: additionalDetails?['budgetRange'],
      budget: additionalDetails?['budget'],
      travelBuddies: additionalDetails?['travelBuddies'] != null 
          ? List<String>.from(additionalDetails!['travelBuddies'])
          : null,
    );
  }

  /// Convert list of TripResponse to list of Trip models
  Future<List<Trip>> mapToTrips(List<TripResponse> responses) async {
    final List<Trip> trips = [];
    for (final response in responses) {
      trips.add(await mapToTrip(response));
    }
    return trips;
  }

  /// Get timeline for a trip with track points and posts
  Future<TimelineResponse> getTimeline(String tripId) async {
    try {
      log('🔵 [TIMELINE] Fetching timeline for trip: $tripId');
      
      final response = await _apiClient.get(
        '/trips/$tripId/timeline',
      );
      
      log('🔵 [TIMELINE] Response status: ${response.statusCode}');
      log('🔵 [TIMELINE] Response data type: ${response.data.runtimeType}');
      log('🔵 [TIMELINE] Has items key: ${(response.data as Map).containsKey('items')}');
      log('🔵 [TIMELINE] Has stats key: ${(response.data as Map).containsKey('stats')}');
      
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        log('🔵 [TIMELINE] Items count in response: ${(data['items'] as List?)?.length ?? 0}');
      }
      
      final timeline = TimelineResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      
      log(
        '🔵 [TIMELINE] Parsed successfully - '
        '${timeline.items.length} items, '
        '${timeline.stats?.totalPhotos ?? 0} photos',
      );
      
      return timeline;
    } catch (e, stackTrace) {
      log('🔴 [TIMELINE] Error fetching timeline: $e', 
          error: e, 
          stackTrace: stackTrace);
      throw Exception('Failed to fetch timeline: $e');
    }
  }
}
