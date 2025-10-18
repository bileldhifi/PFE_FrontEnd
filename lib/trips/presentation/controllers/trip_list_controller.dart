import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/auth/data/models/user.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/trips/data/models/trip.dart';
import 'package:travel_diary_frontend/trips/data/repo/trip_repository.dart';

class TripListState {
  final List<Trip> trips;
  final bool isLoading;
  final String? error;

  TripListState({
    this.trips = const [],
    this.isLoading = false,
    this.error,
  });

  TripListState copyWith({
    List<Trip>? trips,
    bool? isLoading,
    String? error,
  }) {
    return TripListState(
      trips: trips ?? this.trips,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TripListController extends StateNotifier<TripListState> {
  final TripRepository _tripRepository;
  final String _userId;

  TripListController({
    required TripRepository tripRepository,
    required String userId,
  }) : _tripRepository = tripRepository,
       _userId = userId,
       super(TripListState()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    // Don't load trips if user is not authenticated
    if (_userId.isEmpty) {
      state = state.copyWith(
        trips: [],
        isLoading: false,
        error: null,
      );
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final tripResponses = await _tripRepository.getTripsByUser(_userId);
      final trips = await _tripRepository.mapToTrips(tripResponses);
      
      state = state.copyWith(
        trips: trips,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> refresh() async {
    await loadTrips();
  }

  Future<void> deleteTrip(String tripId) async {
    if (_userId.isEmpty) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }
    
    try {
      // Optimistic update
      final updatedTrips = state.trips.where((t) => t.id != tripId).toList();
      state = state.copyWith(trips: updatedTrips);
      
      // Call the real delete API
      await _tripRepository.deleteTrip(tripId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Revert on error
      await loadTrips();
    }
  }

  Future<void> createTrip(String title) async {
    if (_userId.isEmpty) {
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
      );
      return;
    }
    
    try {
      state = state.copyWith(isLoading: true);
      
      final tripResponse = await _tripRepository.startTrip(_userId, title);
      final newTrip = await _tripRepository.mapToTrip(tripResponse);
      
      final updatedTrips = [newTrip, ...state.trips];
      state = state.copyWith(
        trips: updatedTrips,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> createTripWithDetails(String title, Map<String, dynamic>? additionalDetails) async {
    if (_userId.isEmpty) {
      state = state.copyWith(
        error: 'User not authenticated',
        isLoading: false,
      );
      return;
    }
    
    try {
      state = state.copyWith(isLoading: true);
      
      final tripResponse = await _tripRepository.startTripWithDetails(_userId, title, additionalDetails);
      final newTrip = await _tripRepository.mapToTrip(tripResponse);
      
      final updatedTrips = [newTrip, ...state.trips];
      state = state.copyWith(
        trips: updatedTrips,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> endTrip(String tripId) async {
    if (_userId.isEmpty) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }
    
    try {
      final tripResponse = await _tripRepository.endTrip(tripId);
      final updatedTrip = await _tripRepository.mapToTrip(tripResponse);
      
      final updatedTrips = state.trips.map((t) => t.id == tripId ? updatedTrip : t).toList();
      state = state.copyWith(trips: updatedTrips);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final tripListControllerProvider = StateNotifierProvider<TripListController, TripListState>((ref) {
  // Get current user from auth state
  final authState = ref.watch(authControllerProvider);
  final currentUser = authState.user;
  
  // Create controller with current user ID or empty string
  final userId = currentUser?.id ?? '';
  
  return TripListController(
    tripRepository: TripRepository(),
    userId: userId,
  );
});

