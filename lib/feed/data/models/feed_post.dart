import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_diary_frontend/trips/data/models/step_post.dart';

part 'feed_post.freezed.dart';
part 'feed_post.g.dart';

@freezed
class FeedPost with _$FeedPost {
  const factory FeedPost({
    required StepPost step,
    required FeedUser user,
    required String tripTitle,
  }) = _FeedPost;

  factory FeedPost.fromJson(Map<String, dynamic> json) =>
      _$FeedPostFromJson(json);
}

@freezed
class FeedUser with _$FeedUser {
  const factory FeedUser({
    required String id,
    required String username,
    String? avatarUrl,
  }) = _FeedUser;

  factory FeedUser.fromJson(Map<String, dynamic> json) =>
      _$FeedUserFromJson(json);
}

