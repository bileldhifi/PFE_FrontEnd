import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/gradient_header.dart';
import 'package:travel_diary_frontend/core/widgets/retry_widget.dart';
import 'package:travel_diary_frontend/core/widgets/skeleton_loader.dart';
import 'package:travel_diary_frontend/feed/presentation/controllers/feed_controller.dart';
import 'package:travel_diary_frontend/feed/presentation/widgets/post_card.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/like_controller.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/comment_controller.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_manager.dart';
import 'package:travel_diary_frontend/social/data/services/social_websocket_handler.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeWebSocketHandler();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeWebSocketHandler() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final manager = ref.read(webSocketManagerProvider);
      final handler = SocialWebSocketHandler(ref);
      manager.service.registerHandler(handler);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(feedControllerProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 120,
            backgroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: GradientHeader(
                title: 'Explore',
                subtitle: '${feedState.posts.length} ${feedState.posts.length == 1 ? 'post' : 'posts'} from travelers',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => context.push('/search'),
                  ),
                ],
              ),
            ),
          ),
          _buildSliverBody(feedState),
        ],
      ),
    );
  }

  Widget _buildSliverBody(FeedState state) {
    if (state.isLoading && state.posts.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const PostCardSkeleton(),
          childCount: 3,
        ),
      );
    }

    if (state.error != null && state.posts.isEmpty) {
      return SliverFillRemaining(
        child: RetryWidget(
          message: state.error!,
          onRetry: _onRefresh,
        ),
      );
    }

    if (state.posts.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyState(
          icon: Icons.explore_outlined,
          title: 'No Posts Yet',
          message: 'Follow travelers to see their adventures here',
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= state.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = state.posts[index];
          final likeState = ref.watch(likeControllerProvider(post.step.id));
          final commentState = ref.watch(commentControllerProvider(post.step.id));
          
          return PostCard(
            post: post.copyWith(
              step: post.step.copyWith(
                isLiked: likeState.isLiked,
                likesCount: likeState.likesCount,
                commentsCount: commentState.commentsCount,
              ),
            ),
            onLike: () {
              ref.read(likeControllerProvider(post.step.id).notifier).toggleLike();
              final manager = ref.read(webSocketManagerProvider);
              manager.service.subscribe('/topic/posts/${post.step.id}/likes');
            },
            onComment: () {
              _showCommentDialog(context, post.step.id, post);
              final manager = ref.read(webSocketManagerProvider);
              manager.service.subscribe('/topic/posts/${post.step.id}/comments');
            },
            onShare: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon!')),
              );
            },
            onLocationTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location: ${post.step.location.name}'),
                ),
              );
            },
          );
        },
        childCount: state.posts.length + (state.isLoading ? 1 : 0),
      ),
    );
  }

  void _showCommentDialog(BuildContext context, String postId, FeedPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentBottomSheet(
        postId: postId,
        post: post,
      ),
    );
  }
}

class _CommentBottomSheet extends ConsumerStatefulWidget {
  final String postId;
  final FeedPost post;

  const _CommentBottomSheet({
    required this.postId,
    required this.post,
  });

  @override
  ConsumerState<_CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends ConsumerState<_CommentBottomSheet> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentState = ref.watch(commentControllerProvider(widget.postId));
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final targetHeight = screenHeight * 0.75; // 3/4 of screen

    return Container(
      height: targetHeight,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: commentState.isLoading && commentState.comments.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : commentState.comments.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: commentState.comments.length,
                        itemBuilder: (context, index) {
                          final comment = commentState.comments[index];
                          final timeAgo = _formatTimeAgo(comment.createdAt);
                          final authState = ref.watch(authControllerProvider);
                          final isOwner = authState.user?.id == comment.userId;
                          
                          return Dismissible(
                            key: Key(comment.id),
                            direction: isOwner 
                                ? DismissDirection.endToStart 
                                : DismissDirection.none,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                final confirmed = await _showDeleteConfirmation(
                                  context,
                                  comment.content,
                                );
                                if (confirmed) {
                                  try {
                                    await ref
                                        .read(commentControllerProvider(widget.postId).notifier)
                                        .deleteComment(comment.id);
                                    return true;
                                  } catch (e) {
                                    if (mounted) {
                                      final errorMessage = e.toString().contains('404') 
                                          ? 'Comment not found'
                                          : e.toString().contains('403') || 
                                                    e.toString().contains('Not authorized')
                                              ? 'You are not authorized to delete this comment'
                                              : 'Failed to delete comment. Please try again.';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                    return false;
                                  }
                                }
                                return false;
                              }
                              return false;
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      child: Text(
                                        comment.username[0].toUpperCase(),
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                comment.username,
                                                style: theme.textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                timeAgo,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme.colorScheme.outline,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment.content,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: const CircleBorder(),
                  ),
                  onPressed: () async {
                    if (_commentController.text.trim().isNotEmpty) {
                      await ref
                          .read(commentControllerProvider(widget.postId).notifier)
                          .addComment(_commentController.text.trim());
                      _commentController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String commentContent,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Comment',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
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

