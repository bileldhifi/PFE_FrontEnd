import 'package:freezed_annotation/freezed_annotation.dart';

part 'post.freezed.dart';
part 'post.g.dart';

/// Post model representing a travel diary post
@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String text,
    required String visibility,
    required DateTime ts,
    required String tripId,
    required int? trackPointId,
    required double? latitude,
    required double? longitude,
    required String? userId,
    required String userEmail,
    required String username,
    String? city,
    String? country,
    @Default([]) List<PostMedia> media,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => 
      _$PostFromJson(json);
}

/// Media item in a post
@freezed
class PostMedia with _$PostMedia {
  const factory PostMedia({
    required String id,
    required String type,
    required String url,
    required int? sizeBytes,
    required int? width,
    required int? height,
    required int? durationS,
  }) = _PostMedia;

  factory PostMedia.fromJson(Map<String, dynamic> json) => 
      _$PostMediaFromJson(json);
}

