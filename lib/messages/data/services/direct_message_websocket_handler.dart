import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_message.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_message_handler.dart';
import 'package:travel_diary_frontend/messages/data/dtos/direct_message_update.dart';
import 'package:travel_diary_frontend/messages/presentation/controllers/conversation_controller.dart';
import 'package:travel_diary_frontend/messages/presentation/controllers/conversation_list_controller.dart';

class DirectMessageWebSocketHandler implements WebSocketMessageHandler {
  DirectMessageWebSocketHandler(this.ref);

  final Ref ref;

  @override
  WebSocketMessageType get messageType => WebSocketMessageType.chat;

  @override
  String get destinationPattern => '/topic/dm/';

  @override
  bool canHandle(String destination) => destination.startsWith(destinationPattern);

  @override
  bool handleMessage(WebSocketMessage message) {
    try {
      final update = DirectMessageUpdateDto.fromJson(message.body);
      log(
        '[DM WS] Received update for conversation ${update.conversationId} '
        'messageId=${update.message?.id} recipient=${update.recipientId}',
      );
      ref
          .read(conversationListControllerProvider.notifier)
          .handleWebSocketUpdate(update);

      return true;
    } catch (e) {
      log('Error handling direct message WebSocket payload: $e');
      return false;
    }
  }
}

