import 'dart:developer';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';
import 'package:travel_diary_frontend/feed/domain/feed_post_mapper.dart';
import 'package:travel_diary_frontend/post/data/repositories/post_repository.dart';

part 'post_detail_controller.g.dart';

@riverpod
class PostDetailController extends _$PostDetailController {
  late final PostRepository _repository;

  @override
  Future<FeedPost> build(String postId) async {
    _repository = PostRepository();
    return _fetchPost(postId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPost(postId));
  }

  Future<FeedPost> _fetchPost(String postId) async {
    try {
      final post = await _repository.getPostById(postId);
      return FeedPostMapper.fromPost(post);
    } catch (e, stackTrace) {
      log('Error loading post detail $postId: $e', stackTrace: stackTrace);
      throw Exception('Failed to load post: $e');
    }
  }
}

