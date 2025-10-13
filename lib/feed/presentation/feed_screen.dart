import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/retry_widget.dart';
import 'package:travel_diary_frontend/core/widgets/skeleton_loader.dart';
import 'package:travel_diary_frontend/feed/presentation/controllers/feed_controller.dart';
import 'package:travel_diary_frontend/feed/presentation/widgets/post_card.dart';

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: _buildBody(feedState),
    );
  }

  Widget _buildBody(FeedState state) {
    if (state.isLoading && state.posts.isEmpty) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => const PostCardSkeleton(),
      );
    }

    if (state.error != null && state.posts.isEmpty) {
      return RetryWidget(
        message: state.error!,
        onRetry: _onRefresh,
      );
    }

    if (state.posts.isEmpty) {
      return const EmptyState(
        icon: Icons.explore_outlined,
        title: 'No Posts Yet',
        message: 'Follow travelers to see their adventures here',
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.posts.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = state.posts[index];
          return PostCard(
            post: post,
            onLike: () {
              ref.read(feedControllerProvider.notifier).likePost(post.step.id);
            },
            onComment: () {
              // TODO: Open comments
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Comments coming soon!')),
              );
            },
            onShare: () {
              // TODO: Share post
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share coming soon!')),
              );
            },
            onUserTap: () {
              // TODO: Navigate to user profile
              context.push('/profile/${post.user.id}');
            },
            onLocationTap: () {
              // TODO: Show location on map
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location: ${post.step.location.name}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

