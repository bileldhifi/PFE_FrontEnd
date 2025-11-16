import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/notifications/data/dtos/notification_response.dart';
import 'package:travel_diary_frontend/notifications/data/dtos/notification_update.dart';
import 'package:travel_diary_frontend/notifications/data/repositories/notification_repository.dart';

class NotificationState {
  final List<NotificationResponse> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationResponse>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationController extends StateNotifier<NotificationState> {
  final NotificationRepository _repository = NotificationRepository();

  NotificationController() : super(NotificationState());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.getNotifications();
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
      );
    } catch (e) {
      log('Error loading notifications: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      log('Error loading unread count: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      // Update local state
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: (state.unreadCount - 1).clamp(0, double.infinity).toInt(),
      );
    } catch (e) {
      log('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      final updatedNotifications = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      log('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);
      final updatedNotifications = state.notifications
          .where((n) => n.id != notificationId)
          .toList();
      
      final wasUnread = state.notifications
          .firstWhere((n) => n.id == notificationId, orElse: () => state.notifications.first)
          .isRead == false;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: wasUnread 
            ? (state.unreadCount - 1).clamp(0, double.infinity).toInt()
            : state.unreadCount,
      );
    } catch (e) {
      log('Error deleting notification: $e');
      rethrow;
    }
  }

  void updateFromWebSocket(NotificationUpdate update) {
    if (update.notificationId != null && update.type != null) {
      // New notification received
      final newNotification = NotificationResponse(
        id: update.notificationId!,
        actorId: update.actorId ?? '',
        actorUsername: update.actorUsername ?? '',
        actorAvatarUrl: update.actorAvatarUrl,
        type: update.type!,
        createdAt: DateTime.now(),
        isRead: false,
        postId: update.postId,
        commentId: update.commentId,
        content: update.content,
      );
      
      state = state.copyWith(
        notifications: [newNotification, ...state.notifications],
        unreadCount: update.unreadCount,
      );
    } else {
      // Just update unread count (e.g., after marking as read)
      state = state.copyWith(unreadCount: update.unreadCount);
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      loadNotifications(),
      loadUnreadCount(),
    ]);
  }
}

final notificationControllerProvider =
    StateNotifierProvider<NotificationController, NotificationState>(
  (ref) => NotificationController(),
);

