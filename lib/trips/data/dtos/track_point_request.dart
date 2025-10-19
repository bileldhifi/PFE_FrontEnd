import 'package:freezed_annotation/freezed_annotation.dart';

part 'track_point_request.freezed.dart';
part 'track_point_request.g.dart';

/// DTO for creating track points
@freezed
class TrackPointRequest with _$TrackPointRequest {
  const factory TrackPointRequest({
    @JsonKey(name: 'lat') required double latitude,
    @JsonKey(name: 'lon') required double longitude,
    @JsonKey(name: 'accuracyM') double? accuracyMeters,
    @JsonKey(name: 'speedMps') double? speedMps,
  }) = _TrackPointRequest;

  factory TrackPointRequest.fromJson(Map<String, dynamic> json) =>
      _$TrackPointRequestFromJson(json);
}
