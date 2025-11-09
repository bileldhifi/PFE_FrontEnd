import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';
import 'package:travel_diary_frontend/feed/domain/feed_post_mapper.dart';
import 'package:travel_diary_frontend/post/data/repositories/post_repository.dart';

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
  final PostRepository _repository = PostRepository();

  FeedController() : super(FeedState()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final posts = await _repository.getPublicPosts();
      log('Loaded ${posts.length} public posts');
      final feedPosts = posts.map(FeedPostMapper.fromPost).toList();
      
      state = state.copyWith(
        posts: feedPosts,
        isLoading: false,
        currentPage: 1,
        hasMore: feedPosts.length >= 10, // Assume more if we got 10+ posts
      );
    } catch (e) {
      log('Error loading feed: $e');
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
      final posts = await _repository.getPublicPosts();
      final feedPosts = posts.map(FeedPostMapper.fromPost).toList();
      
      state = state.copyWith(
        posts: [...state.posts, ...feedPosts],
        isLoading: false,
        currentPage: state.currentPage + 1,
        hasMore: false,
      );
    } catch (e) {
      log('Error loading more feed: $e');
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

}

final feedControllerProvider = StateNotifierProvider<FeedController, FeedState>((ref) {
  return FeedController();
});

