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
import 'package:travel_diary_frontend/feed/presentation/widgets/comment_bottom_sheet.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/like_controller.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/comment_controller.dart';
import 'package:travel_diary_frontend/core/websocket/websocket_manager.dart';
import 'package:travel_diary_frontend/social/data/services/social_websocket_handler.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/notifications/data/services/notification_websocket_handler.dart';
import 'package:travel_diary_frontend/notifications/presentation/controllers/notification_controller.dart';

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
    // WebSocket is now initialized centrally via WebSocketInitializer
    // This method is kept for backward compatibility but does nothing
    // Subscriptions are handled centrally and persist across navigation
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
      builder: (context) => CommentBottomSheet(
        postId: postId,
        post: post,
      ),
    );
  }
}
