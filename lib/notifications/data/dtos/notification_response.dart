import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_diary_frontend/notifications/data/models/notification_type.dart';

part 'notification_response.freezed.dart';
part 'notification_response.g.dart';

@freezed
class NotificationResponse with _$NotificationResponse {
  const factory NotificationResponse({
    required String id,
    required String actorId,
    required String actorUsername,
    String? actorAvatarUrl,
    required NotificationType type,
    required DateTime createdAt,
    required bool isRead,
    String? postId,
    String? commentId,
    String? content,
  }) = _NotificationResponse;

  factory NotificationResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationResponseFromJson(json);
}

