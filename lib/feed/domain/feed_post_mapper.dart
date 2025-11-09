import 'dart:developer';

import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';
import 'package:travel_diary_frontend/post/data/models/post.dart';
import 'package:travel_diary_frontend/trips/data/models/media.dart';
import 'package:travel_diary_frontend/trips/data/models/step_post.dart';

class FeedPostMapper {
  static FeedPost fromPost(Post post) {
    final photos = post.media
        .map(
          (media) => Media(
            id: media.id,
            url: media.url,
            type: media.type,
          ),
        )
        .toList();

    final stepPost = StepPost(
      id: post.id,
      tripId: post.tripId,
      text: post.text,
      location: LocationData(
        lat: post.latitude ?? 0.0,
        lng: post.longitude ?? 0.0,
        name: post.city ?? post.country ?? 'Unknown',
        city: post.city,
        country: post.country,
      ),
      takenAt: post.ts,
      photos: photos,
      visibility: post.visibility,
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
      createdAt: post.ts,
    );

    if (post.userId == null || post.userId!.isEmpty) {
      log('Error: Post ${post.id} missing userId, cannot create FeedUser');
      throw Exception('Post missing userId');
    }

    final feedUser = FeedUser(
      id: post.userId!,
      username: post.username,
      avatarUrl: null,
    );

    return FeedPost(
      step: stepPost,
      user: feedUser,
      tripTitle: post.city ?? post.country ?? 'Trip',
    );
  }
}

