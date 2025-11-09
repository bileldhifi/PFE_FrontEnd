import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_message.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_message_handler.dart';
import 'package:travel_diary_frontend/notifications/data/dtos/notification_update.dart';
import 'package:travel_diary_frontend/notifications/presentation/controllers/notification_controller.dart';

/// Handler for notification-related WebSocket messages
class NotificationWebSocketHandler implements WebSocketMessageHandler {
  final Ref ref;

  NotificationWebSocketHandler(this.ref);

  @override
  WebSocketMessageType get messageType => WebSocketMessageType.notification;

  @override
  String get destinationPattern => '/topic/notifications/';

  @override
  bool handleMessage(WebSocketMessage message) {
    try {
      if (message.destination.contains('/topic/notifications/')) {
        return _handleNotificationUpdate(message);
      }
      return false;
    } catch (e) {
      log('Error handling notification WebSocket message: $e');
      return false;
    }
  }

  bool _handleNotificationUpdate(WebSocketMessage message) {
    try {
      log('Received notification update: ${message.body}');
      final update = NotificationUpdate.fromJson(message.body);
      log('Parsed notification update: userId=${update.userId}, type=${update.type}, unreadCount=${update.unreadCount}');
      
      // Update controller directly - Riverpod handles state updates safely
      final controller = ref.read(notificationControllerProvider.notifier);
      controller.updateFromWebSocket(update);
      log('Notification update processed successfully');
      
      return true;
    } catch (e, stackTrace) {
      log('Error parsing notification update: $e');
      log('Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  bool canHandle(String destination) {
    return destination.contains('/topic/notifications/');
  }
}

