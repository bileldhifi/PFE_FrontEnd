import 'dart:developer';
import 'package:travel_diary_frontend/core/websocket/websocket_message.dart';

/// Interface for handling WebSocket messages
/// Each feature (social, chat, notifications) should implement this
abstract class WebSocketMessageHandler {
  /// The message type this handler processes
  WebSocketMessageType get messageType;

  /// The destination pattern this handler listens to
  /// e.g., '/topic/posts/{postId}/likes'
  String get destinationPattern;

  /// Handle an incoming WebSocket message
  /// Returns true if the message was handled, false otherwise
  bool handleMessage(WebSocketMessage message);

  /// Check if this handler can handle a given destination
  bool canHandle(String destination) {
    return destination.contains(destinationPattern) ||
        destination.endsWith(destinationPattern);
  }
}

/// Registry for message handlers
class WebSocketMessageHandlerRegistry {
  final List<WebSocketMessageHandler> _handlers = [];

  void register(WebSocketMessageHandler handler) {
    _handlers.add(handler);
    log('Registered WebSocket handler: ${handler.runtimeType}');
  }

  void unregister(WebSocketMessageHandler handler) {
    _handlers.remove(handler);
    log('Unregistered WebSocket handler: ${handler.runtimeType}');
  }

  List<WebSocketMessageHandler> getHandlersForDestination(String destination) {
    return _handlers.where((handler) => handler.canHandle(destination)).toList();
  }

  List<WebSocketMessageHandler> getHandlersForType(WebSocketMessageType type) {
    return _handlers.where((handler) => handler.messageType == type).toList();
  }

  void clear() {
    _handlers.clear();
  }
}

