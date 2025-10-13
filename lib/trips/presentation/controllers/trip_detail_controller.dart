import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/core/data/fake_data.dart';
import 'package:travel_diary_frontend/trips/data/models/step_post.dart';
import 'package:travel_diary_frontend/trips/data/models/trip.dart';
import 'package:travel_diary_frontend/trips/presentation/controllers/trip_list_controller.dart';

class TripDetailState {
  final Trip? trip;
  final List<StepPost> steps;
  final bool isLoading;
  final String? error;

  TripDetailState({
    this.trip,
    this.steps = const [],
    this.isLoading = false,
    this.error,
  });

  TripDetailState copyWith({
    Trip? trip,
    List<StepPost>? steps,
    bool? isLoading,
    String? error,
  }) {
    return TripDetailState(
      trip: trip ?? this.trip,
      steps: steps ?? this.steps,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TripDetailController extends StateNotifier<TripDetailState> {
  final String tripId;
  final Ref ref;
  
  TripDetailController(this.tripId, this.ref) : super(TripDetailState()) {
    loadTripDetail();
  }

  Future<void> loadTripDetail() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get trips from the trip list provider
      final tripListState = ref.read(tripListControllerProvider);
      
      // Check if trip exists
      Trip? trip;
      try {
        trip = tripListState.trips.firstWhere((t) => t.id == tripId);
      } catch (e) {
        // Trip not found in current list
        trip = null;
      }
      
      if (trip == null) {
        state = state.copyWith(
          trip: null,
          steps: const [],
          isLoading: false,
          error: 'Trip not found',
        );
        return;
      }
      
      final steps = FakeData.getStepsForTrip(tripId);
      
      state = state.copyWith(
        trip: trip,
        steps: steps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> addStep(StepPost step) async {
    try {
      // Optimistic update
      final updatedSteps = [step, ...state.steps];
      state = state.copyWith(steps: updatedSteps);
      
      // In real app, call API
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await loadTripDetail();
    }
  }

  Future<void> deleteStep(String stepId) async {
    try {
      final updatedSteps = state.steps.where((s) => s.id != stepId).toList();
      state = state.copyWith(steps: updatedSteps);
      
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      state = state.copyWith(error: e.toString());
      await loadTripDetail();
    }
  }
}

final tripDetailControllerProvider = StateNotifierProvider.family<TripDetailController, TripDetailState, String>(
  (ref, tripId) => TripDetailController(tripId, ref),
);

