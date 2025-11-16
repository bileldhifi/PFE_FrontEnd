import 'package:freezed_annotation/freezed_annotation.dart';

part 'websocket_message.freezed.dart';
part 'websocket_message.g.dart';

/// Base WebSocket message type
@freezed
class WebSocketMessage with _$WebSocketMessage {
  const factory WebSocketMessage({
    required String type,
    required String destination,
    required Map<String, dynamic> body,
    String? id,
    Map<String, String>? headers,
  }) = _WebSocketMessage;

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) =>
      _$WebSocketMessageFromJson(json);
}

/// WebSocket message types
enum WebSocketMessageType {
  like,
  comment,
  notification,
  chat,
  typing,
  online,
  unknown,
}

extension WebSocketMessageTypeExtension on String {
  WebSocketMessageType toMessageType() {
    switch (this) {
      case 'LIKE_UPDATE':
      case '/topic/posts/':
        return WebSocketMessageType.like;
      case 'COMMENT_UPDATE':
        return WebSocketMessageType.comment;
      case 'NOTIFICATION':
        return WebSocketMessageType.notification;
      default:
        if (startsWith('/topic/dm/')) {
          return WebSocketMessageType.chat;
        }
        return WebSocketMessageType.unknown;
    }
  }
}

