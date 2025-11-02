import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_diary_frontend/trips/data/models/timeline_item.dart';

part 'timeline_response.freezed.dart';
part 'timeline_response.g.dart';

/// Complete timeline response with items and statistics
@freezed
class TimelineResponse with _$TimelineResponse {
  const factory TimelineResponse({
    @Default([]) List<TimelineItem> items,
    TimelineStats? stats,
  }) = _TimelineResponse;

  factory TimelineResponse.fromJson(Map<String, dynamic> json) =>
      _$TimelineResponseFromJson(json);
}

/// Timeline statistics
@freezed
class TimelineStats with _$TimelineStats {
  const factory TimelineStats({
    @Default(0.0) double totalDistanceKm,
    @Default(0) int totalDurationSeconds,
    @Default(0.0) double avgSpeedKmh,
    @Default(0.0) double maxSpeedKmh,
    @Default(0) int totalPhotos,
    @Default(0) int totalTrackPoints,
  }) = _TimelineStats;

  factory TimelineStats.fromJson(Map<String, dynamic> json) =>
      _$TimelineStatsFromJson(json);
}

/// Extension methods for TimelineStats
extension TimelineStatsExtensions on TimelineStats {
  /// Get formatted total distance
  String get formattedTotalDistance {
    if (totalDistanceKm < 1) {
      return '${(totalDistanceKm * 1000).toStringAsFixed(0)}m';
    }
    return '${totalDistanceKm.toStringAsFixed(2)}km';
  }
  
  /// Get formatted total duration
  String get formattedTotalDuration {
    final hours = totalDurationSeconds ~/ 3600;
    final minutes = (totalDurationSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }
  
  /// Get formatted average speed
  String get formattedAvgSpeed {
    return '${avgSpeedKmh.toStringAsFixed(1)} km/h';
  }
  
  /// Get formatted max speed
  String get formattedMaxSpeed {
    return '${maxSpeedKmh.toStringAsFixed(1)} km/h';
  }
}

