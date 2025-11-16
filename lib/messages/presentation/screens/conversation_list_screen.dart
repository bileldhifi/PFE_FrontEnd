import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/core/widgets/error_widget.dart';
import 'package:travel_diary_frontend/core/widgets/loading_widget.dart';
import 'package:travel_diary_frontend/messages/data/dtos/conversation_dto.dart';
import 'package:travel_diary_frontend/messages/presentation/controllers/conversation_list_controller.dart';
import 'package:travel_diary_frontend/messages/presentation/screens/conversation_screen.dart';
import 'package:travel_diary_frontend/profile/presentation/controllers/profile_controller.dart';
import 'package:travel_diary_frontend/core/widgets/app_avatar.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationListControllerProvider);

    final background = Theme.of(context).colorScheme.background;

    return Scaffold(
      backgroundColor: background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(conversationListControllerProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar(
              pinned: true,
              title: Text('Messages'),
              centerTitle: true,
            ),
          if (state.isLoading && state.conversations.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: LoadingWidget()),
            )
          else if (state.error != null && state.conversations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref
                      .read(conversationListControllerProvider.notifier)
                      .refresh(),
                ),
              ),
            )
          else if (state.conversations.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No messages yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Start a conversation from a profile.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
            )
            else
              SliverList.builder(
                itemCount: state.conversations.length,
                itemBuilder: (context, index) {
                  final conversation = state.conversations[index];
                  return _ConversationTile(conversation: conversation);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  const _ConversationTile({required this.conversation});

  final ConversationDto conversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodySmall;
    final unread = conversation.unreadCount > 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: AppAvatar(
        size: 44,
        imageUrl: conversation.otherAvatarUrl,
        name: conversation.otherUsername,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.otherUsername,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: unread ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      subtitle: conversation.lastMessage != null
          ? Text(
              conversation.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subtitleStyle?.copyWith(
                fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
              ),
            )
          : const Text(
              'Say hi 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: unread
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
            ),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationScreen(
              conversationId: conversation.id,
              otherUserId: conversation.otherUserId,
              otherUsername: conversation.otherUsername,
              otherAvatarUrl: conversation.otherAvatarUrl,
            ),
          ),
        );
        ref.read(conversationListControllerProvider.notifier).refresh();
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    if (now.difference(timestamp).inDays == 0) {
      final hour = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = timestamp.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } else if (now.difference(timestamp).inDays == 1) {
      return 'Yesterday';
    }
    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}

