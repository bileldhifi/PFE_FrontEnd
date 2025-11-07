import 'package:freezed_annotation/freezed_annotation.dart';

part 'like_response.freezed.dart';
part 'like_response.g.dart';

@freezed
class LikeResponse with _$LikeResponse {
  const factory LikeResponse({
    required String id,
    required String postId,
    required String userId,
    required String username,
    required DateTime createdAt,
  }) = _LikeResponse;

  factory LikeResponse.fromJson(Map<String, dynamic> json) =>
      _$LikeResponseFromJson(json);
}

