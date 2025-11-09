import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_message.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_message_handler.dart';
import 'package:travel_diary_frontend/social/data/dtos/post_like_update.dart';
import 'package:travel_diary_frontend/social/data/dtos/post_comment_update.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/like_controller.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/comment_controller.dart';

/// Handler for social-related WebSocket messages (likes, comments)
class SocialWebSocketHandler implements WebSocketMessageHandler {
  final Ref ref;

  SocialWebSocketHandler(this.ref);

  @override
  WebSocketMessageType get messageType => WebSocketMessageType.like;

  @override
  String get destinationPattern => '/topic/posts/';

  @override
  bool handleMessage(WebSocketMessage message) {
    try {
      if (message.destination.contains('/likes')) {
        return _handleLikeUpdate(message);
      } else if (message.destination.contains('/comments')) {
        return _handleCommentUpdate(message);
      }
      return false;
    } catch (e) {
      log('Error handling social WebSocket message: $e');
      return false;
    }
  }

  bool _handleLikeUpdate(WebSocketMessage message) {
    try {
      final update = PostLikeUpdate.fromJson(message.body);
      final controller = ref.read(likeControllerProvider(update.postId).notifier);
      controller.updateFromWebSocket(update);
      return true;
    } catch (e) {
      log('Error parsing like update: $e');
      return false;
    }
  }

  bool _handleCommentUpdate(WebSocketMessage message) {
    try {
      final update = PostCommentUpdate.fromJson(message.body);
      final controller = ref.read(commentControllerProvider(update.postId).notifier);
      controller.updateFromWebSocket(update);
      return true;
    } catch (e) {
      log('Error parsing comment update: $e');
      return false;
    }
  }

  @override
  bool canHandle(String destination) {
    return destination.contains('/topic/posts/') &&
        (destination.contains('/likes') || destination.contains('/comments'));
  }
}

