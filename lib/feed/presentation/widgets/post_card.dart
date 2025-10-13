import 'package:flutter/material.dart';
import 'package:travel_diary_frontend/core/utils/date_time.dart';
import 'package:travel_diary_frontend/core/widgets/app_avatar.dart';
import 'package:travel_diary_frontend/core/widgets/app_network_image.dart';
import 'package:travel_diary_frontend/feed/data/models/feed_post.dart';

class PostCard extends StatefulWidget {
  final FeedPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onUserTap;
  final VoidCallback onLocationTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onUserTap,
    required this.onLocationTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
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
              onTap: widget.onUserTap,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.post.user.username,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
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
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // TODO: Show options menu
              },
            ),
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

  Widget _buildPhotoGrid(int photoCount) {
    final photos = widget.post.step.photos;

    if (photoCount == 1) {
      return AspectRatio(
        aspectRatio: photos[0].ratio,
        child: AppNetworkImage(
          imageUrl: photos[0].url,
          width: double.infinity,
        ),
      );
    }

    if (photoCount == 2) {
      return Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: AppNetworkImage(imageUrl: photos[0].url),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: AppNetworkImage(imageUrl: photos[1].url),
            ),
          ),
        ],
      );
    }

    // 3+ photos
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: AppNetworkImage(imageUrl: photos[0].url),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: AppNetworkImage(imageUrl: photos[1].url),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(imageUrl: photos[2].url),
                    if (photoCount > 3)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Text(
                            '+${photoCount - 3}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

