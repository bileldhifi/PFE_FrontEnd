import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_like_update.freezed.dart';
part 'post_like_update.g.dart';

@freezed
class PostLikeUpdate with _$PostLikeUpdate {
  const factory PostLikeUpdate({
    required String postId,
    required String userId,
    required String username,
    required bool isLiked,
    required int likesCount,
  }) = _PostLikeUpdate;

  factory PostLikeUpdate.fromJson(Map<String, dynamic> json) =>
      _$PostLikeUpdateFromJson(json);
}

