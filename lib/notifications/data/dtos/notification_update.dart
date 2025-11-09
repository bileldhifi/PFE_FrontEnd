import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_diary_frontend/notifications/data/models/notification_type.dart';

part 'notification_update.freezed.dart';
part 'notification_update.g.dart';

@freezed
class NotificationUpdate with _$NotificationUpdate {
  const factory NotificationUpdate({
    String? notificationId,
    required String userId,
    String? actorId,
    String? actorUsername,
    String? actorAvatarUrl,
    NotificationType? type,
    String? postId,
    String? commentId,
    String? content,
    required int unreadCount,
  }) = _NotificationUpdate;

  factory NotificationUpdate.fromJson(Map<String, dynamic> json) =>
      _$NotificationUpdateFromJson(json);
}

