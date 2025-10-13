import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/core/data/fake_data.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';

class FeedState {
  final List<FeedPost> posts;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  FeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
  });

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class FeedController extends StateNotifier<FeedState> {
  FeedController() : super(FeedState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final posts = FakeData.feedPosts;
      
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        currentPage: 1,
        hasMore: true,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    
    state = state.copyWith(isLoading: true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final morePosts = FakeData.getMoreFeedPosts(state.currentPage + 1);
      
      // For demo, stop after 2 pages
      state = state.copyWith(
        posts: [...state.posts, ...morePosts],
        isLoading: false,
        currentPage: state.currentPage + 1,
        hasMore: state.currentPage < 1,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> refresh() async {
    state = FeedState();
    await loadInitial();
  }

  Future<void> likePost(String postId) async {
    // In real app, call API
    final updatedPosts = state.posts.map((post) {
      if (post.step.id == postId) {
        return post.copyWith(
          step: post.step.copyWith(
            isLiked: !post.step.isLiked,
            likesCount: post.step.isLiked 
                ? post.step.likesCount - 1 
                : post.step.likesCount + 1,
          ),
        );
      }
      return post;
    }).toList();
    
    state = state.copyWith(posts: updatedPosts);
  }
}

final feedControllerProvider = StateNotifierProvider<FeedController, FeedState>((ref) {
  return FeedController();
});

