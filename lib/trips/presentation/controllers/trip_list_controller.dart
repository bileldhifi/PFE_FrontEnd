import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/core/data/fake_data.dart';
import 'package:travel_diary_frontend/trips/data/models/trip.dart';

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
  TripListController() : super(TripListState()) {
    loadTrips();
  }

  Future<void> loadTrips() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final trips = FakeData.myTrips;
      
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
    try {
      // Optimistic update
      final updatedTrips = state.trips.where((t) => t.id != tripId).toList();
      state = state.copyWith(trips: updatedTrips);
      
      // In real app, call API
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      state = state.copyWith(error: e.toString());
      // Revert on error
      await loadTrips();
    }
  }

  Future<void> createTrip(Trip trip) async {
    try {
      state = state.copyWith(isLoading: true);
      
      // In real app, call API
      await Future.delayed(const Duration(milliseconds: 500));
      
      final updatedTrips = [trip, ...state.trips];
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
}

final tripListControllerProvider = StateNotifierProvider<TripListController, TripListState>((ref) {
  return TripListController();
});

