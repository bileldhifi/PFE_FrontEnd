import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_manager.dart';
import 'package:travel_diary_frontend/social/data/services/social_websocket_handler.dart';
import 'package:travel_diary_frontend/notifications/data/services/notification_websocket_handler.dart';

/// Centralized WebSocket initialization
/// This ensures handlers are registered once and subscriptions persist
class WebSocketInitializer {
  static bool _isInitialized = false;
  
  /// Initialize WebSocket handlers and subscriptions
  /// Should be called once when user is authenticated
  static void initialize(Ref ref) {
    if (_isInitialized) {
      log('WebSocket already initialized');
      return;
    }
    
    final manager = ref.read(webSocketManagerProvider);
    final authState = ref.read(authControllerProvider);
    
    if (!authState.isAuthenticated || authState.user == null) {
      log('User not authenticated, skipping WebSocket initialization');
      return;
    }
    
    // Register all handlers once (even if not connected yet)
    final socialHandler = SocialWebSocketHandler(ref);
    final notificationHandler = NotificationWebSocketHandler(ref);
    
    manager.service.registerHandler(socialHandler);
    manager.service.registerHandler(notificationHandler);
    
    log('Registered WebSocket handlers: Social, Notification');
    
    // Subscribe to notification topic (will be queued if not connected)
    final userId = authState.user!.id;
    final notificationTopic = '/topic/notifications/$userId';
    manager.service.subscribe(notificationTopic);
    log('Subscribed to notification topic: $notificationTopic');
    
    // Also listen to messages stream to ensure handlers are active
    manager.service.messages.listen((message) {
      // Messages are automatically routed to handlers via _routeMessage
      // This subscription ensures the stream is active
    });
    
    _isInitialized = true;
  }
  
  /// Re-initialize when user changes or reconnects
  static void reinitialize(Ref ref) {
    _isInitialized = false;
    initialize(ref);
  }
  
  /// Reset initialization state (e.g., on logout)
  static void reset() {
    _isInitialized = false;
  }
}

