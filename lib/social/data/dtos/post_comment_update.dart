import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_comment_update.freezed.dart';
part 'post_comment_update.g.dart';

@freezed
class PostCommentUpdate with _$PostCommentUpdate {
  const factory PostCommentUpdate({
    required String postId,
    String? commentId,
    String? userId,
    String? username,
    String? content,
    required int commentsCount,
  }) = _PostCommentUpdate;

  factory PostCommentUpdate.fromJson(Map<String, dynamic> json) =>
      _$PostCommentUpdateFromJson(json);
}

