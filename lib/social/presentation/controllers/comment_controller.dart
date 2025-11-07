import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_diary_frontend/social/data/repositories/comment_repository.dart';
import 'package:travel_diary_frontend/social/data/dtos/comment_response.dart';
import 'package:travel_diary_frontend/social/data/dtos/post_comment_update.dart';

class CommentState {
  final List<CommentResponse> comments;
  final int commentsCount;
  final bool isLoading;
  final String? error;

  CommentState({
    this.comments = const [],
    this.commentsCount = 0,
    this.isLoading = false,
    this.error,
  });

  CommentState copyWith({
    List<CommentResponse>? comments,
    int? commentsCount,
    bool? isLoading,
    String? error,
  }) {
    return CommentState(
      comments: comments ?? this.comments,
      commentsCount: commentsCount ?? this.commentsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CommentController extends StateNotifier<CommentState> {
  final CommentRepository _repository;
  final String postId;

  CommentController(this.postId)
      : _repository = CommentRepository(),
        super(CommentState()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final comments = await _repository.getComments(postId);
      state = state.copyWith(
        comments: comments,
        commentsCount: comments.length,
        isLoading: false,
      );
    } catch (e) {
      log('Error loading comments: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> addComment(String content) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final update = await _repository.addComment(postId, content);
      await loadComments();
    } catch (e) {
      log('Error adding comment: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> deleteComment(String commentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteComment(commentId);
      final updatedComments =
          state.comments.where((c) => c.id != commentId).toList();
      state = state.copyWith(
        comments: updatedComments,
        commentsCount: updatedComments.length,
        isLoading: false,
      );
    } catch (e) {
      log('Error deleting comment: $e');
      final errorMessage = e.toString().contains('404') 
          ? 'Comment not found'
          : e.toString().contains('403') || e.toString().contains('Not authorized')
              ? 'Not authorized to delete this comment'
              : 'Failed to delete comment. Please try again.';
      state = state.copyWith(
        error: errorMessage,
        isLoading: false,
      );
      rethrow; // Re-throw so the UI can handle it
    }
  }

  void updateFromWebSocket(PostCommentUpdate update) {
    if (update.postId == postId) {
      if (update.commentId != null && update.content != null) {
        final newComment = CommentResponse(
          id: update.commentId!,
          postId: update.postId,
          userId: update.userId ?? '',
          username: update.username ?? '',
          content: update.content!,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(
          comments: [...state.comments, newComment],
          commentsCount: update.commentsCount,
        );
      } else {
        state = state.copyWith(
          commentsCount: update.commentsCount,
        );
      }
    }
  }
}

final commentControllerProvider =
    StateNotifierProvider.family<CommentController, CommentState, String>(
  (ref, postId) => CommentController(postId),
);

