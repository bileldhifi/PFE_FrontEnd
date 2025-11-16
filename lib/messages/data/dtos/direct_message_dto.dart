import 'package:freezed_annotation/freezed_annotation.dart';

part 'direct_message_dto.freezed.dart';
part 'direct_message_dto.g.dart';

@freezed
class DirectMessageDto with _$DirectMessageDto {
  const factory DirectMessageDto({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _DirectMessageDto;

  factory DirectMessageDto.fromJson(Map<String, dynamic> json) =>
      _$DirectMessageDtoFromJson(json);
}

