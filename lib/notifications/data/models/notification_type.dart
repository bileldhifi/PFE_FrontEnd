import 'package:freezed_annotation/freezed_annotation.dart';

enum NotificationType {
  @JsonValue('LIKE')
  like,
  @JsonValue('COMMENT')
  comment,
  @JsonValue('FOLLOW')
  follow,
  @JsonValue('NEW_POST')
  newPost,
  @JsonValue('MENTION')
  mention,
}

