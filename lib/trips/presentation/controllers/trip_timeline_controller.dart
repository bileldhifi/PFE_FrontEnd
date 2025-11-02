import 'dart:developer';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travel_diary_frontend/trips/data/models/timeline_response.dart';
import 'package:travel_diary_frontend/trips/data/repo/trip_repository.dart';

part 'trip_timeline_controller.freezed.dart';
part 'trip_timeline_controller.g.dart';

/// Timeline state
@freezed
class TripTimelineState with _$TripTimelineState {
  const factory TripTimelineState({
    TimelineResponse? timeline,
    @Default(false) bool isLoading,
    String? error,
  }) = _TripTimelineState;
}

/// Trip timeline controller
@riverpod
class TripTimelineController extends _$TripTimelineController {
  late final TripRepository _repository;

  @override
  TripTimelineState build(String tripId) {
    _repository = TripRepository();
    // Schedule loading after build completes
    Future.microtask(() => loadTimeline());
    return const TripTimelineState(isLoading: true);
  }

  /// Load timeline data
  Future<void> loadTimeline() async {
    log('🟢 [CONTROLLER] Starting to load timeline for trip: $tripId');
    
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final timeline = await _repository.getTimeline(tripId);
      
      log('🟢 [CONTROLLER] Timeline loaded successfully: '
          '${timeline.items.length} items');
      
      state = state.copyWith(
        timeline: timeline,
        isLoading: false,
        error: null,
      );
      
      log('🟢 [CONTROLLER] State updated - isLoading: false, '
          'items: ${timeline.items.length}');
    } catch (e, stackTrace) {
      log('🔴 [CONTROLLER] Error loading timeline: $e',
          error: e,
          stackTrace: stackTrace);
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      
      log('🔴 [CONTROLLER] State updated with error: $e');
    }
  }

  /// Refresh timeline
  Future<void> refresh() async {
    await loadTimeline();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

