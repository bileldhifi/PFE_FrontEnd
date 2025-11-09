import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';
import 'package:travel_diary_frontend/feed/presentation/controllers/post_detail_controller.dart';
import 'package:travel_diary_frontend/feed/presentation/widgets/comment_bottom_sheet.dart';
import 'package:travel_diary_frontend/feed/presentation/widgets/post_card.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/comment_controller.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/like_controller.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_manager.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToRealtime();
    });
  }

  void _subscribeToRealtime() {
    final manager = ref.read(webSocketManagerProvider);
    manager.service.subscribe('/topic/posts/${widget.postId}/likes');
    manager.service.subscribe('/topic/posts/${widget.postId}/comments');
  }

  Future<void> _showCommentSheet(BuildContext context, FeedPost post) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(
        postId: post.step.id,
        post: post,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postDetailControllerProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(postDetailControllerProvider(widget.postId).notifier)
                  .refresh();
            },
          ),
        ],
      ),
      body: postAsync.when(
        data: (post) {
          final likeState = ref.watch(likeControllerProvider(post.step.id));
          final commentState =
              ref.watch(commentControllerProvider(post.step.id));

          final updatedPost = post.copyWith(
            step: post.step.copyWith(
              isLiked: likeState.isLiked,
              likesCount: likeState.likesCount,
              commentsCount: commentState.commentsCount,
            ),
          );

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(postDetailControllerProvider(widget.postId).notifier)
                  .refresh();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                PostCard(
                  post: updatedPost,
                  onLike: () {
                    ref
                        .read(likeControllerProvider(post.step.id).notifier)
                        .toggleLike();
                    _subscribeToRealtime();
                  },
                  onComment: () {
                    _showCommentSheet(context, updatedPost);
                    _subscribeToRealtime();
                  },
                  onShare: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share coming soon!')),
                    );
                  },
                  onLocationTap: () {
                    final name = updatedPost.step.location.name ?? 'Unknown';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Location: $name')),
                    );
                  },
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to previous screen'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(24),
          child: SelectableText.rich(
            TextSpan(
              text: 'Failed to load post\n',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
              children: [
                TextSpan(
                  text: error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

