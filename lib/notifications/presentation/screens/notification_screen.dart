import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/core/utils/date_time.dart';
import 'package:travel_diary_frontend/core/widgets/app_avatar.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/retry_widget.dart';
import 'package:travel_diary_frontend/core/widgets/skeleton_loader.dart';
import 'package:travel_diary_frontend/notifications/data/models/notification_type.dart';
import 'package:travel_diary_frontend/notifications/presentation/controllers/notification_controller.dart';
import 'package:travel_diary_frontend/notifications/data/dtos/notification_response.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_manager.dart';
import 'package:travel_diary_frontend/notifications/data/services/notification_websocket_handler.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/feed/presentation/widgets/post_card.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeWebSocket();
      ref.read(notificationControllerProvider.notifier).refresh();
    });
  }

  void _initializeWebSocket() {
    // WebSocket is now initialized centrally via WebSocketInitializer
    // Subscriptions persist across navigation, so we just ensure subscription exists
    final manager = ref.read(webSocketManagerProvider);
    final authState = ref.read(authControllerProvider);
    
    if (authState.isAuthenticated && authState.user != null) {
      final topic = '/topic/notifications/${authState.user!.id}';
      // Subscribe (will be queued if not connected, or added to active subscriptions)
      manager.service.subscribe(topic);
      log('Ensured subscription to notification topic: $topic');
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(notificationControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: theme.textTheme.titleLarge,
        ),
        elevation: 0,
        actions: [
          if (notificationState.unreadCount > 0)
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(notificationControllerProvider.notifier)
                      .markAllAsRead();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All notifications marked as read'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to mark all as read: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: _buildBody(context, notificationState, theme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationState state,
    ThemeData theme,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const SkeletonLoader();
    }

    if (state.error != null && state.notifications.isEmpty) {
      return RetryWidget(
        message: state.error!,
        onRetry: _onRefresh,
      );
    }

    final notifications = state.notifications;
    final header = _NotificationHeader(
      unreadCount: state.unreadCount,
      isLoading: state.isLoading,
    );

    if (notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: [
          header,
          const SizedBox(height: 32),
          const EmptyState(
            icon: Icons.notifications_none_outlined,
            title: 'No Notifications',
            message: 'You\'re all caught up!',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      itemCount: notifications.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return header;
        }

        final notification = notifications[index - 1];
        final timeAgo = DateTimeUtils.getRelativeTime(notification.createdAt);
        final icon = _getNotificationIcon(notification.type);
        final color = _getNotificationColor(notification.type, theme);
        final label = _getNotificationLabel(notification.type);
        final message = notification.content ??
            _generateNotificationContent(notification);

        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: const _DeleteBackground(),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              return _showDeleteConfirmation(context);
            }
            return false;
          },
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              ref
                  .read(notificationControllerProvider.notifier)
                  .deleteNotification(notification.id);
            }
          },
          child: _NotificationCard(
            notification: notification,
            timeAgo: timeAgo,
            accentColor: color,
            icon: icon,
            label: label,
            message: message,
            onTap: () => _handleNotificationTap(context, notification),
            onMarkRead: notification.isRead
                ? null
                : () async {
                    try {
                      await ref
                          .read(notificationControllerProvider.notifier)
                          .markAsRead(notification.id);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to mark as read: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    return switch (type) {
      NotificationType.like => Icons.favorite,
      NotificationType.comment => Icons.comment,
      NotificationType.follow => Icons.person_add,
      NotificationType.newPost => Icons.add_circle,
      NotificationType.mention => Icons.alternate_email,
    };
  }

  Color _getNotificationColor(NotificationType type, ThemeData theme) {
    return switch (type) {
      NotificationType.like => Colors.red,
      NotificationType.comment => theme.colorScheme.primary,
      NotificationType.follow => Colors.blue,
      NotificationType.newPost => Colors.green,
      NotificationType.mention => Colors.purple,
    };
  }

  String _getNotificationLabel(NotificationType type) {
    return switch (type) {
      NotificationType.like => 'Like',
      NotificationType.comment => 'Comment',
      NotificationType.follow => 'New follower',
      NotificationType.newPost => 'New post',
      NotificationType.mention => 'Mention',
    };
  }

  String _generateNotificationContent(NotificationResponse notification) {
    final actorName = notification.actorUsername;
    return switch (notification.type) {
      NotificationType.like => '$actorName liked your post',
      NotificationType.comment => '$actorName commented on your post',
      NotificationType.follow => '$actorName started following you',
      NotificationType.newPost => '$actorName posted something new',
      NotificationType.mention => '$actorName mentioned you',
    };
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationResponse notification,
  ) {
    // Mark as read if unread
    if (!notification.isRead) {
      ref
          .read(notificationControllerProvider.notifier)
          .markAsRead(notification.id);
    }

    // Navigate based on notification type
    if (notification.postId != null) {
      context.push('/posts/${notification.postId}');
    } else if (notification.type == NotificationType.follow) {
      // Navigate to user profile
      if (notification.actorId != null) {
        context.push('/users/${notification.actorId}/profile');
      }
    }
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Notification',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete this notification?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({
    required this.unreadCount,
    required this.isLoading,
  });

  final int unreadCount;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Stay in the loop',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _NotificationStatChip(
                label: 'Unread',
                value: unreadCount.toString(),
                isHighlighted: true,
              ),
              const SizedBox(width: 12),
              _NotificationStatChip(
                label: isLoading ? 'Syncing…' : 'Real-time updates',
                value: isLoading ? '' : 'On',
                isHighlighted: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationStatChip extends StatelessWidget {
  const _NotificationStatChip({
    required this.label,
    required this.value,
    required this.isHighlighted,
  });

  final String label;
  final String value;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final isEmptyValue = value.isEmpty;
    final backgroundColor = isHighlighted
        ? Colors.white
        : Colors.white.withOpacity(isEmptyValue ? 0.12 : 0.18);
    final textColor =
        isHighlighted ? Colors.black87 : Colors.white.withOpacity(0.85);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEmptyValue) ...[
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      alignment: Alignment.centerRight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Icon(
            Icons.delete_forever_rounded,
            color: Colors.white,
            size: 26,
          ),
          SizedBox(height: 4),
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.timeAgo,
    required this.icon,
    required this.accentColor,
    required this.label,
    required this.message,
    required this.onTap,
    this.onMarkRead,
  });

  final NotificationResponse notification;
  final String timeAgo;
  final IconData icon;
  final Color accentColor;
  final String label;
  final String message;
  final VoidCallback onTap;
  final Future<void> Function()? onMarkRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;
    final surfaceColor = theme.colorScheme.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: isUnread
              ? LinearGradient(
                  colors: [
                    accentColor.withOpacity(0.18),
                    accentColor.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUnread ? null : surfaceColor,
          border: Border.all(
            color: isUnread
                ? accentColor.withOpacity(0.28)
                : theme.colorScheme.outlineVariant.withOpacity(0.25),
          ),
          boxShadow: [
            if (isUnread)
              BoxShadow(
                color: accentColor.withOpacity(0.16),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(
                  imageUrl: notification.actorAvatarUrl,
                  name: notification.actorUsername,
                  size: 52,
                  showBorder: !isUnread,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _NotificationTypeBadge(
                            icon: icon,
                            label: label,
                            accentColor: accentColor,
                            isUnread: isUnread,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              timeAgo,
                              textAlign: TextAlign.right,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isUnread
                                    ? Colors.white.withOpacity(0.85)
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isUnread
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              isUnread ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onMarkRead != null) ...[
                  const SizedBox(width: 8),
                  _MarkReadButton(
                    onPressed: onMarkRead!,
                    isUnread: isUnread,
                    accentColor: accentColor,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _ActorName(
                  username: notification.actorUsername,
                  isUnread: isUnread,
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: Color(0xFFB0B0B0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTypeBadge extends StatelessWidget {
  const _NotificationTypeBadge({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isUnread,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final background = isUnread
        ? Colors.white.withOpacity(0.18)
        : accentColor.withOpacity(0.12);
    final textColor = isUnread ? Colors.white : accentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkReadButton extends StatelessWidget {
  const _MarkReadButton({
    required this.onPressed,
    required this.isUnread,
    required this.accentColor,
  });

  final Future<void> Function() onPressed;
  final bool isUnread;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final iconColor = isUnread ? Colors.white : accentColor;

    return IconButton(
      iconSize: 22,
      splashRadius: 20,
      onPressed: () {
        onPressed();
      },
      icon: Icon(
        Icons.check_circle_rounded,
        color: iconColor,
      ),
      tooltip: 'Mark as read',
    );
  }
}

class _ActorName extends StatelessWidget {
  const _ActorName({
    required this.username,
    required this.isUnread,
  });

  final String username;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUnread
        ? Colors.white.withOpacity(0.85)
        : theme.colorScheme.outline;

    return Row(
      children: [
        Icon(
          Icons.person_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          username,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}