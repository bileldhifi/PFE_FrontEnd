import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/social/data/repositories/like_repository.dart';
import 'package:travel_diary_frontend/social/data/dtos/post_like_update.dart';

class LikeState {
  final bool isLiked;
  final int likesCount;
  final bool isLoading;
  final String? error;

  LikeState({
    this.isLiked = false,
    this.likesCount = 0,
    this.isLoading = false,
    this.error,
  });

  LikeState copyWith({
    bool? isLiked,
    int? likesCount,
    bool? isLoading,
    String? error,
  }) {
    return LikeState(
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class LikeController extends StateNotifier<LikeState> {
  final LikeRepository _repository;
  final String postId;

  LikeController(this.postId)
      : _repository = LikeRepository(),
        super(LikeState()) {
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    try {
      final isLiked = await _repository.isLiked(postId);
      final likes = await _repository.getLikes(postId);
      state = state.copyWith(
        isLiked: isLiked,
        likesCount: likes.length,
      );
    } catch (e) {
      log('Error checking like status: $e');
    }
  }

  Future<void> toggleLike() async {
    if (state.isLiked) {
      await unlike();
    } else {
      await like();
    }
  }

  Future<void> like() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final update = await _repository.likePost(postId);
      state = state.copyWith(
        isLiked: update.isLiked,
        likesCount: update.likesCount,
        isLoading: false,
      );
    } catch (e) {
      log('Error liking post: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> unlike() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final update = await _repository.unlikePost(postId);
      state = state.copyWith(
        isLiked: update.isLiked,
        likesCount: update.likesCount,
        isLoading: false,
      );
    } catch (e) {
      log('Error unliking post: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void updateFromWebSocket(PostLikeUpdate update) {
    if (update.postId == postId) {
      state = state.copyWith(
        isLiked: update.isLiked,
        likesCount: update.likesCount,
      );
    }
  }
}

final likeControllerProvider =
    StateNotifierProvider.family<LikeController, LikeState, String>(
  (ref, postId) => LikeController(postId),
);

