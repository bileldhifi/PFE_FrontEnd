import 'package:freezed_annotation/freezed_annotation.dart';

part 'follow_response.freezed.dart';
part 'follow_response.g.dart';

@freezed
class FollowResponse with _$FollowResponse {
  const factory FollowResponse({
    String? id,
    required String followerId,
    String? followerUsername,
    required String followingId,
    String? followingUsername,
    DateTime? createdAt,
  }) = _FollowResponse;

  factory FollowResponse.fromJson(Map<String, dynamic> json) =>
      _$FollowResponseFromJson(json);
}

