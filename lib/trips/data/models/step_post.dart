import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_diary_frontend/trips/data/models/media.dart';

part 'step_post.freezed.dart';
part 'step_post.g.dart';

@freezed
class StepPost with _$StepPost {
  const factory StepPost({
    required String id,
    required String tripId,
    String? title,
    String? text,
    required LocationData location,
    required DateTime takenAt,
    @Default([]) List<Media> photos,
    @Default('PUBLIC') String visibility,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    @Default(false) bool isLiked,
    required DateTime createdAt,
  }) = _StepPost;

  factory StepPost.fromJson(Map<String, dynamic> json) =>
      _$StepPostFromJson(json);
}

@freezed
class LocationData with _$LocationData {
  const factory LocationData({
    required double lat,
    required double lng,
    String? name,
    String? city,
    String? country,
    String? countryCode,
  }) = _LocationData;

  factory LocationData.fromJson(Map<String, dynamic> json) =>
      _$LocationDataFromJson(json);
}

