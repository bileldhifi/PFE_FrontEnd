import 'dart:math';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'track_point.freezed.dart';
part 'track_point.g.dart';

/// TrackPoint model representing a location point in a trip
@freezed
class TrackPoint with _$TrackPoint {
  const factory TrackPoint({
    required int id,
    required String tripId,
    required DateTime timestamp,
    required double latitude,
    required double longitude,
    double? accuracyMeters,
    double? speedMps,
    // Calculated fields
    double? speedKmh,
    String? locationName,
    @Default(false) bool isSignificant,
  }) = _TrackPoint;

  factory TrackPoint.fromJson(Map<String, dynamic> json) =>
      _$TrackPointFromJson(json);
}


/// Extension methods for TrackPoint calculations
extension TrackPointExtensions on TrackPoint {
  /// Calculates distance to another track point using Haversine formula
  double distanceTo(TrackPoint other) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = latitude * (3.14159265359 / 180);
    final double lat2Rad = other.latitude * (3.14159265359 / 180);
    final double deltaLatRad = (other.latitude - latitude) * (3.14159265359 / 180);
    final double deltaLonRad = (other.longitude - longitude) * (3.14159265359 / 180);

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculates time difference with another track point in seconds
  int timeDifferenceSeconds(TrackPoint other) {
    return timestamp.difference(other.timestamp).inSeconds.abs();
  }


  /// Validates if the track point has valid coordinates
  bool get isValidLocation {
    return latitude >= -90.0 && 
           latitude <= 90.0 && 
           longitude >= -180.0 && 
           longitude <= 180.0;
  }

  /// Gets formatted speed in km/h
  String get formattedSpeed {
    if (speedKmh == null) return 'N/A';
    return '${speedKmh!.toStringAsFixed(1)} km/h';
  }

  /// Gets formatted accuracy
  String get formattedAccuracy {
    if (accuracyMeters == null) return 'N/A';
    return '${accuracyMeters!.toStringAsFixed(1)}m';
  }
}

