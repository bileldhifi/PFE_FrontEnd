import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/core/utils/date_time.dart';
import 'package:travel_diary_frontend/core/widgets/app_avatar.dart';
import 'package:travel_diary_frontend/core/widgets/app_network_image.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';
import 'package:travel_diary_frontend/trips/presentation/widgets/simple_image_viewer.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/follow_controller.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';

const String _kBaseUrl = 'http://localhost:8089/app-backend';

String _buildImageUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  return '$_kBaseUrl$url';
}

class PostCard extends ConsumerStatefulWidget {
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onLocationTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onLocationTap,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isExpanded = false;
  final int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final step = widget.post.step;
    final hasLongText = (step.text?.length ?? 0) > 150;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: AppAvatar(
              imageUrl: widget.post.user.avatarUrl,
              name: widget.post.user.username,
              size: 44,
              onTap: () => context.push('/users/${widget.post.user.id}/profile'),
            ),
            title: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/users/${widget.post.user.id}/profile'),
                    child: Text(
                      widget.post.user.username,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.tripTitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateTimeUtils.getRelativeTime(step.takenAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: _buildHeaderActions(context),
          ),

          // Title (if exists)
          if (step.title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                step.title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Text content
          if (step.text != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.text!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: _isExpanded ? null : _maxLines,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (hasLongText) ...[
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 30),
                      ),
                      child: Text(_isExpanded ? 'Show less' : 'Read more'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Photos
          if (step.photos.isNotEmpty) ...[
            _buildPhotoGrid(step.photos.length),
            const SizedBox(height: 12),
          ],

          // Location
          if (step.location.name != null) ...[
            InkWell(
              onTap: widget.onLocationTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${step.location.name}${step.location.city != null ? ', ${step.location.city}' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Divider
          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    step.isLiked ? Icons.favorite : Icons.favorite_border,
                    color: step.isLiked ? Colors.red : null,
                  ),
                  onPressed: widget.onLike,
                ),
                Text(
                  step.likesCount.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: widget.onComment,
                ),
                Text(
                  step.commentsCount.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: widget.onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final postUserId = widget.post.user.id;
    
    // Debug: Log user IDs
    log('PostCard - Current user ID: ${authState.user?.id}, Post user ID: $postUserId');
    
    // Compare user IDs as strings to handle UUID format differences
    final isCurrentUser = authState.user?.id != null && 
                          postUserId.isNotEmpty &&
                          authState.user!.id.toString() == postUserId.toString();

    if (isCurrentUser) {
      return IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {
          // TODO: Show options menu (edit, delete, etc.)
        },
      );
    }

    // Show follow button for all non-current users
    // If userId is invalid, the follow controller will handle errors gracefully
    final followState = postUserId.isNotEmpty
        ? ref.watch(followControllerProvider(postUserId))
        : FollowState();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (followState.isLoading)
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          TextButton(
            onPressed: followState.isLoading
                ? null
                : () async {
                    try {
                      await ref
                          .read(followControllerProvider(widget.post.user.id).notifier)
                          .toggleFollow();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to ${followState.isFollowing ? 'unfollow' : 'follow'} user. Please try again.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              followState.isFollowing ? 'Following' : 'Follow',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: followState.isFollowing
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Show options menu (report, etc.)
          },
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(int photoCount) {
    final photos = widget.post.step.photos;
    final locationName = widget.post.step.location.name ?? 
                         widget.post.step.location.city ?? 
                         widget.post.step.location.country ?? 
                         '';

    void _showImageViewer(int initialIndex) {
      final imageUrls = photos.map((p) => p.url).toList();
      final locationNames = List<String>.generate(
        imageUrls.length,
        (_) => locationName,
      );
      SimpleImageViewer.show(
        context,
        imageUrls: imageUrls,
        initialIndex: initialIndex,
        locationNames: locationNames,
      );
    }

    if (photoCount == 1) {
      return GestureDetector(
        onTap: () => _showImageViewer(0),
        child: AspectRatio(
          aspectRatio: photos[0].ratio,
          child: AppNetworkImage(
            imageUrl: _buildImageUrl(photos[0].url),
            width: double.infinity,
          ),
        ),
      );
    }

    if (photoCount == 2) {
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showImageViewer(0),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppNetworkImage(
                  imageUrl: _buildImageUrl(photos[0].url),
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: GestureDetector(
              onTap: () => _showImageViewer(1),
              child: AspectRatio(
                aspectRatio: 1,
                child: AppNetworkImage(
                  imageUrl: _buildImageUrl(photos[1].url),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 3+ photos
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showImageViewer(0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: AppNetworkImage(
              imageUrl: _buildImageUrl(photos[0].url),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _showImageViewer(1),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppNetworkImage(
                    imageUrl: _buildImageUrl(photos[1].url),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: GestureDetector(
                onTap: () => _showImageViewer(2),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(
                        imageUrl: _buildImageUrl(photos[2].url),
                      ),
                      if (photoCount > 3)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              '+${photoCount - 3}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

