import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/track_point.dart';

part 'track_point_response.freezed.dart';
part 'track_point_response.g.dart';

/// DTO for track point API responses
@freezed
class TrackPointResponse with _$TrackPointResponse {
  const factory TrackPointResponse({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'tripId') required String tripId,
    @JsonKey(name: 'ts') required DateTime timestamp,
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lon') required double longitude,
    @JsonKey(name: 'accuracyM') double? accuracyMeters,
    @JsonKey(name: 'speedMps') double? speedMps,
    @JsonKey(name: 'speedKmh') double? speedKmh,
    @JsonKey(name: 'locationName') String? locationName,
    @JsonKey(name: 'isSignificant') @Default(false) bool isSignificant,
  }) = _TrackPointResponse;

  factory TrackPointResponse.fromJson(Map<String, dynamic> json) =>
      _$TrackPointResponseFromJson(json);
}

/// Extension methods for TrackPointResponse
extension TrackPointResponseExtensions on TrackPointResponse {
  /// Converts TrackPointResponse to TrackPoint
  TrackPoint toTrackPoint() {
    return TrackPoint(
      id: id,
      tripId: tripId,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      speedMps: speedMps,
      speedKmh: speedKmh,
      locationName: locationName,
      isSignificant: isSignificant,
    );
  }
}
