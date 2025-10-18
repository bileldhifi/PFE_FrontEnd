import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_response.freezed.dart';
part 'trip_response.g.dart';

@freezed
class TripResponse with _$TripResponse {
  const factory TripResponse({
    required String id,
    required String title,
    required DateTime startedAt,
    DateTime? endedAt,
    required String userEmail,
  }) = _TripResponse;

  factory TripResponse.fromJson(Map<String, dynamic> json) =>
      _$TripResponseFromJson(json);
}
