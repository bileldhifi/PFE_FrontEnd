import 'dart:developer';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';

part 'post_controller.g.dart';

/// State for post creation
class PostCreationState {
  final bool isLoading;
  final String? error;
  final Post? createdPost;

  const PostCreationState({
    this.isLoading = false,
    this.error,
    this.createdPost,
  });

  PostCreationState copyWith({
    bool? isLoading,
    String? error,
    Post? createdPost,
  }) {
    return PostCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdPost: createdPost ?? this.createdPost,
    );
  }
}

/// Controller for post operations
/// Uses Riverpod for state management
@riverpod
class PostController extends _$PostController {
  late final PostRepository _repository;

  @override
  PostCreationState build() {
    _repository = PostRepository();
    return const PostCreationState();
  }

  /// Create a new post with images
  /// 
  /// Returns created post on success
  /// Updates state with error on failure
  Future<Post?> createPost({
    required String tripId,
    int? trackPointId,
    required double latitude,
    required double longitude,
    String? caption,
    required String visibility,
    String? city,
    String? country,
    required List<File> images,
  }) async {
    if (images.isEmpty) {
      state = state.copyWith(
        error: 'Please select at least one image',
      );
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      log('Creating post for trip: $tripId, city: $city, country: $country');
      
      final post = await _repository.createPost(
        tripId: tripId,
        trackPointId: trackPointId,
        latitude: latitude,
        longitude: longitude,
        caption: caption,
        visibility: visibility,
        city: city,
        country: country,
        images: images,
      );

      log('Post created successfully: ${post.id}');
      
      state = state.copyWith(
        isLoading: false,
        createdPost: post,
      );

      return post;
    } catch (e) {
      log('Error creating post', error: e);
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );

      return null;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = const PostCreationState();
  }
}

