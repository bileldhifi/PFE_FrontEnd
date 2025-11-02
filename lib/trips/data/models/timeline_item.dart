import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_diary_frontend/post/data/models/post.dart';

part 'timeline_item.freezed.dart';
part 'timeline_item.g.dart';

/// Timeline item combining track point data with associated posts
@freezed
class TimelineItem with _$TimelineItem {
  const factory TimelineItem({
    // Track Point Data
    required int trackPointId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    String? locationName,
    double? speedKmh,
    double? accuracyMeters,
    @Default(false) bool isSignificant,
    
    // Calculated Data
    double? distanceFromPreviousKm,
    int? timeFromPreviousSeconds,
    
    // Associated Posts
    @Default([]) List<Post> posts,
    @Default(0) int photoCount,
  }) = _TimelineItem;

  factory TimelineItem.fromJson(Map<String, dynamic> json) =>
      _$TimelineItemFromJson(json);
}

/// Extension methods for TimelineItem
extension TimelineItemExtensions on TimelineItem {
  /// Check if this timeline item has media
  bool get hasMedia => photoCount > 0;
  
  /// Get formatted location string
  String get formattedLocation {
    if (locationName != null && locationName!.isNotEmpty) {
      return locationName!;
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }
  
  /// Get formatted speed
  String get formattedSpeed {
    if (speedKmh == null) return 'N/A';
    return '${speedKmh!.toStringAsFixed(1)} km/h';
  }
  
  /// Get formatted distance from previous
  String get formattedDistanceFromPrevious {
    if (distanceFromPreviousKm == null) return '';
    if (distanceFromPreviousKm! < 1) {
      return '${(distanceFromPreviousKm! * 1000).toStringAsFixed(0)}m';
    }
    return '${distanceFromPreviousKm!.toStringAsFixed(2)}km';
  }
  
  /// Get formatted accuracy
  String get formattedAccuracy {
    if (accuracyMeters == null) return 'N/A';
    return '${accuracyMeters!.toStringAsFixed(1)}m';
  }
}

