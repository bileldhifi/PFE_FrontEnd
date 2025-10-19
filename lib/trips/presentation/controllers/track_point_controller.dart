import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_diary_frontend/trips/data/models/track_point.dart';
import 'package:travel_diary_frontend/trips/data/dtos/track_point_request.dart';
import 'package:travel_diary_frontend/trips/data/repo/track_point_repository.dart';
import 'package:travel_diary_frontend/trips/data/services/track_point_batcher.dart';

part 'track_point_controller.freezed.dart';

/// State for track point operations
@freezed
class TrackPointState with _$TrackPointState {
  const factory TrackPointState({
    @Default([]) List<TrackPoint> trackPoints,
    @Default(false) bool isLoading,
    @Default(false) bool isTracking,
    String? error,
    String? successMessage,
    TrackPoint? latestTrackPoint,
    @Default(0.0) double totalDistance,
    @Default(0) int totalPoints,
    @Default(0) int batchSize,
    @Default(false) bool isBatching,
  }) = _TrackPointState;
}

/// Controller for managing track point state and operations
class TrackPointController extends StateNotifier<TrackPointState> {
  final TrackPointRepository _trackPointRepository;
  final String _tripId;
  late final TrackPointBatcher _batcher;

  TrackPointController({
    required TrackPointRepository trackPointRepository,
    required String tripId,
  })  : _trackPointRepository = trackPointRepository,
        _tripId = tripId,
        super(const TrackPointState()) {
    _initializeBatcher();
  }
  
  void _initializeBatcher() {
    _batcher = TrackPointBatcher(
      repository: _trackPointRepository,
      tripId: _tripId,
      onError: (error) {
        state = state.copyWith(error: error);
      },
      onBatchSent: (count) {
        state = state.copyWith(
          successMessage: 'Batch of $count points sent successfully',
          batchSize: _batcher.batchSize,
        );
        // Reload track points to get updated data
        loadTrackPoints();
      },
      onBatchQueued: (size) {
        state = state.copyWith(
          batchSize: size,
          isBatching: _batcher.isProcessing,
        );
      },
    );
  }

  /// Load all track points for the trip
  Future<void> loadTrackPoints() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final responses = await _trackPointRepository.getTrackPoints(_tripId);
      final trackPoints = _trackPointRepository.mapToTrackPoints(responses);
      
      state = state.copyWith(
        trackPoints: trackPoints,
        isLoading: false,
        totalPoints: trackPoints.length,
      );
      
      // Calculate total distance
      await _calculateTotalDistance();
      
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Add a single track point (immediate)
  Future<void> addTrackPoint(TrackPointRequest request) async {
    if (!_trackPointRepository.validateTrackPoint(request)) {
      state = state.copyWith(error: 'Invalid track point data');
      return;
    }

    try {
      final response = await _trackPointRepository.addTrackPoint(_tripId, request);
      
      if (response != null) {
        final newTrackPoint = _trackPointRepository.mapToTrackPoint(response);
        final updatedTrackPoints = [...state.trackPoints, newTrackPoint];
        
        state = state.copyWith(
          trackPoints: updatedTrackPoints,
          latestTrackPoint: newTrackPoint,
          totalPoints: updatedTrackPoints.length,
          successMessage: 'Track point added successfully',
        );
        
        // Recalculate total distance
        await _calculateTotalDistance();
      } else {
        // Track point was skipped due to optimization
        state = state.copyWith(
          successMessage: 'Track point added (optimized)',
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
  
  /// Add a track point to the batch (optimized)
  void addTrackPointToBatch(TrackPointRequest request) {
    if (!_trackPointRepository.validateTrackPoint(request)) {
      state = state.copyWith(error: 'Invalid track point data');
      return;
    }
    
    _batcher.addTrackPoint(request);
    state = state.copyWith(
      successMessage: 'Track point queued for batch (${_batcher.batchSize} points)',
    );
  }
  
  /// Force flush the current batch
  Future<void> flushBatch() async {
    await _batcher.flush();
  }

  /// Add multiple track points in bulk
  Future<void> addTrackPointsBulk(List<TrackPointRequest> requests) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final responses = await _trackPointRepository.addTrackPointsBulk(_tripId, requests);
      final newTrackPoints = _trackPointRepository.mapToTrackPoints(responses);
      
      final updatedTrackPoints = [...state.trackPoints, ...newTrackPoints];
      
      state = state.copyWith(
        trackPoints: updatedTrackPoints,
        isLoading: false,
        totalPoints: updatedTrackPoints.length,
        successMessage: '${newTrackPoints.length} track points added successfully',
      );
      
      // Update latest track point
      if (newTrackPoints.isNotEmpty) {
        state = state.copyWith(
          latestTrackPoint: newTrackPoints.last,
        );
      }
      
      // Recalculate total distance
      await _calculateTotalDistance();
      
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Get track points within a time range
  Future<void> getTrackPointsByTimeRange(DateTime startTime, DateTime endTime) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final responses = await _trackPointRepository.getTrackPointsByTimeRange(
        _tripId, 
        startTime, 
        endTime,
      );
      final trackPoints = _trackPointRepository.mapToTrackPoints(responses);
      
      state = state.copyWith(
        trackPoints: trackPoints,
        isLoading: false,
        totalPoints: trackPoints.length,
      );
      
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Get track points near a location
  Future<void> getTrackPointsNearLocation(
      double latitude, 
      double longitude, 
      double radiusMeters) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final responses = await _trackPointRepository.getTrackPointsNearLocation(
        _tripId, 
        latitude, 
        longitude, 
        radiusMeters,
      );
      final trackPoints = _trackPointRepository.mapToTrackPoints(responses);
      
      state = state.copyWith(
        trackPoints: trackPoints,
        isLoading: false,
        totalPoints: trackPoints.length,
      );
      
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  /// Get the latest track point
  Future<void> getLatestTrackPoint() async {
    try {
      final response = await _trackPointRepository.getLatestTrackPoint(_tripId);
      
      if (response != null) {
        final latestTrackPoint = _trackPointRepository.mapToTrackPoint(response);
        state = state.copyWith(latestTrackPoint: latestTrackPoint);
      } else {
        state = state.copyWith(latestTrackPoint: null);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a track point
  Future<void> deleteTrackPoint(int trackPointId) async {
    try {
      await _trackPointRepository.deleteTrackPoint(_tripId, trackPointId);
      
      final updatedTrackPoints = state.trackPoints
          .where((tp) => tp.id != trackPointId)
          .toList();
      
      state = state.copyWith(
        trackPoints: updatedTrackPoints,
        totalPoints: updatedTrackPoints.length,
        successMessage: 'Track point deleted successfully',
      );
      
      // Recalculate total distance
      await _calculateTotalDistance();
      
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Start tracking (for real-time location updates)
  void startTracking() {
    state = state.copyWith(isTracking: true);
  }

  /// Stop tracking
  void stopTracking() {
    state = state.copyWith(isTracking: false);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  /// Calculate total distance for the trip
  Future<void> _calculateTotalDistance() async {
    try {
      final distance = await _trackPointRepository.getTotalDistance(_tripId);
      state = state.copyWith(totalDistance: distance);
    } catch (e) {
      // If API fails, calculate locally
      final localDistance = _calculateLocalDistance();
      state = state.copyWith(totalDistance: localDistance);
    }
  }

  /// Calculate distance locally using track points
  double _calculateLocalDistance() {
    if (state.trackPoints.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < state.trackPoints.length; i++) {
      totalDistance += state.trackPoints[i - 1].distanceTo(state.trackPoints[i]);
    }
    
    return totalDistance;
  }

  /// Get formatted total distance
  String get formattedTotalDistance {
    if (state.totalDistance < 1000) {
      return '${state.totalDistance.toStringAsFixed(0)}m';
    } else {
      return '${(state.totalDistance / 1000).toStringAsFixed(2)}km';
    }
  }

  /// Get track points count
  int get trackPointsCount => state.trackPoints.length;

  /// Check if tracking is active
  bool get isTracking => state.isTracking;

  /// Get latest track point
  TrackPoint? get latestTrackPoint => state.latestTrackPoint;
  
  /// Dispose resources
  @override
  void dispose() {
    _batcher.dispose();
    super.dispose();
  }
}

/// Provider for TrackPointController
final trackPointControllerProvider = StateNotifierProvider.family<TrackPointController, TrackPointState, String>((ref, tripId) {
  return TrackPointController(
    trackPointRepository: TrackPointRepository(),
    tripId: tripId,
  );
});
