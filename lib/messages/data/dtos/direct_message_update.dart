import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travel_diary_frontend/messages/data/dtos/direct_message_dto.dart';

part 'direct_message_update.freezed.dart';
part 'direct_message_update.g.dart';

@freezed
class DirectMessageUpdateDto with _$DirectMessageUpdateDto {
  const factory DirectMessageUpdateDto({
    required String conversationId,
    DirectMessageDto? message,
    String? recipientId,
    int? recipientUnreadCount,
  }) = _DirectMessageUpdateDto;

  factory DirectMessageUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$DirectMessageUpdateDtoFromJson(json);
}

