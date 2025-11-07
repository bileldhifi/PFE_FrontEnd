import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/social/data/repositories/follow_repository.dart';

class FollowState {
  final bool isFollowing;
  final bool isLoading;
  final String? error;

  FollowState({
    this.isFollowing = false,
    this.isLoading = false,
    this.error,
  });

  FollowState copyWith({
    bool? isFollowing,
    bool? isLoading,
    String? error,
  }) {
    return FollowState(
      isFollowing: isFollowing ?? this.isFollowing,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FollowController extends StateNotifier<FollowState> {
  final FollowRepository _repository;
  final String userId;

  FollowController(this.userId)
      : _repository = FollowRepository(),
        super(FollowState()) {
    // Check follow status asynchronously without blocking
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await _repository.isFollowing(userId);
      state = state.copyWith(isFollowing: isFollowing);
    } catch (e) {
      log('Error checking follow status: $e');
      // Don't update state on error, just log it
      // This allows the follow button to work even if status check fails
    }
  }

  Future<void> follow() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.followUser(userId);
      state = state.copyWith(isFollowing: true, isLoading: false);
      log('Successfully followed user: $userId');
    } catch (e) {
      log('Error following user: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow; // Re-throw so UI can handle it
    }
  }

  Future<void> unfollow() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.unfollowUser(userId);
      state = state.copyWith(isFollowing: false, isLoading: false);
      log('Successfully unfollowed user: $userId');
    } catch (e) {
      log('Error unfollowing user: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow; // Re-throw so UI can handle it
    }
  }

  Future<void> toggleFollow() async {
    if (state.isFollowing) {
      await unfollow();
    } else {
      await follow();
    }
  }
}

final followControllerProvider =
    StateNotifierProvider.family<FollowController, FollowState, String>(
  (ref, userId) => FollowController(userId),
);

