import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_request.freezed.dart';
part 'trip_request.g.dart';

@freezed
class TripRequest with _$TripRequest {
  const factory TripRequest({
    required String title,
  }) = _TripRequest;

  factory TripRequest.fromJson(Map<String, dynamic> json) =>
      _$TripRequestFromJson(json);
}
