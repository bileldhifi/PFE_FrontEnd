import 'package:travel_diary_frontend/core/network/api_client.dart';
import 'package:travel_diary_frontend/trips/data/dtos/trip_request.dart';
import 'package:travel_diary_frontend/trips/data/dtos/trip_response.dart';
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
      visibility: additionalDetails?['visibility'] ?? 'PUBLIC',
      stats: const TripStats(), // Default stats since backend doesn't have this field
      createdBy: response.userEmail, // Using email as createdBy for now
      createdAt: response.startedAt,
      description: additionalDetails?['description'],
      coverUrl: additionalDetails?['coverUrl'],
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
}
