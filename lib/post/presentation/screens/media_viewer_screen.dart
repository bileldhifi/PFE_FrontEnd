import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../../core/widgets/loading_widget.dart';

/// Screen to view media at a track point (like Snapchat map)
/// Allows swiping through all posts and media at this location
class MediaViewerScreen extends ConsumerStatefulWidget {
  final int trackPointId;
  final String locationName;

  const MediaViewerScreen({
    super.key,
    required this.trackPointId,
    required this.locationName,
  });

  @override
  ConsumerState<MediaViewerScreen> createState() => 
      _MediaViewerScreenState();
}

class _MediaViewerScreenState 
    extends ConsumerState<MediaViewerScreen> {
  
  final PageController _pageController = PageController();
  final PostRepository _repository = PostRepository();
  
  List<Post>? _posts;
  bool _isLoading = true;
  String? _error;
  int _currentPostIndex = 0;
  
  // Track current image index for each post
  final Map<int, int> _currentImageIndices = {};

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final posts = await _repository.getPostsByTrackPoint(
        widget.trackPointId.toString(),
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }

      log('Loaded ${posts.length} posts for track point');
    } catch (e) {
      log('Error loading posts: $e', error: e);
      if (mounted) {
        setState(() {
          _error = 'Failed to load media';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          if (_isLoading)
            const Center(child: LoadingWidget())
          else if (_error != null)
            _ErrorView(
              error: _error!,
              onRetry: _loadPosts,
            )
          else if (_posts == null || _posts!.isEmpty)
            const _EmptyView()
          else
            _MediaPageView(
              posts: _posts!,
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() => _currentPostIndex = index);
              },
              onImageChanged: (postIndex, imageIndex) {
                setState(() {
                  _currentImageIndices[postIndex] = imageIndex;
                });
              },
              currentImageIndices: _currentImageIndices,
            ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              locationName: widget.locationName,
              onClose: () => context.pop(),
            ),
          ),

          // Progress indicators - Instagram style
          if (_posts != null && _posts!.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 8,
              right: 8,
              child: _InstagramStyleProgress(
                posts: _posts!,
                currentPostIndex: _currentPostIndex,
                currentImageIndices: _currentImageIndices,
              ),
            ),

          // Bottom action bar with navigation
          if (_posts != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomActionBar(
                posts: _posts!,
                currentPostIndex: _currentPostIndex,
              ),
            ),
          
        ],
      ),
    );
  }
}

/// Responsive helper for screen-aware sizing
class _ResponsiveHelper {
  final BuildContext context;
  
  _ResponsiveHelper(this.context);
  
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  
  // Responsive button size
  double get buttonSize {
    if (screenWidth < 375) return 36; // Small phones
    if (screenWidth > 600) return 48; // Tablets
    return 40; // Standard phones
  }
  
  // Responsive icon size
  double get iconSize {
    if (screenWidth < 375) return 16; // Small phones
    if (screenWidth > 600) return 24; // Tablets
    return 20; // Standard phones
  }
  
  // Responsive padding
  double get padding {
    if (screenWidth < 375) return 16; // Small phones
    if (screenWidth > 600) return 28; // Tablets
    return 20; // Standard phones
  }
  
  // Responsive spacing
  double get spacing {
    if (screenWidth < 375) return 8; // Small phones
    if (screenWidth > 600) return 16; // Tablets
    return 12; // Standard phones
  }
}

/// Sleek minimal top bar with responsive design
class _TopBar extends StatelessWidget {
  final String locationName;
  final VoidCallback onClose;

  const _TopBar({
    required this.locationName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = _ResponsiveHelper(context);
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: responsive.padding,
        right: responsive.padding,
        bottom: responsive.padding,
      ),
      child: Row(
        children: [
          // Back/Close button - minimalist circle
          _CircleButton(
            onTap: onClose,
            icon: Icons.arrow_back_ios_new_rounded,
            size: responsive.buttonSize,
            iconSize: responsive.iconSize,
          ),
          
          SizedBox(width: responsive.spacing),
          
          // Location chip - sleek and minimal
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.padding * 0.8,
                vertical: responsive.padding * 0.5,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: responsive.iconSize * 0.8,
                  ),
                  SizedBox(width: responsive.spacing * 0.66),
                  Expanded(
                    child: Text(
                      locationName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(width: responsive.spacing),
          
          // Menu button
          _CircleButton(
            onTap: () {
              // TODO: Show options menu
            },
            icon: Icons.more_horiz_rounded,
            size: responsive.buttonSize,
            iconSize: responsive.iconSize,
          ),
        ],
      ),
    );
  }
}

/// Reusable circle button with responsive sizing
class _CircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double size;
  final double iconSize;

  const _CircleButton({
    required this.onTap,
    required this.icon,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Instagram-style progress bars
/// Shows progress for each post and images within posts
class _InstagramStyleProgress extends StatelessWidget {
  final List<Post> posts;
  final int currentPostIndex;
  final Map<int, int> currentImageIndices;

  const _InstagramStyleProgress({
    required this.posts,
    required this.currentPostIndex,
    required this.currentImageIndices,
  });

  @override
  Widget build(BuildContext context) {
    final currentPost = posts[currentPostIndex];
    final currentImageIndex = currentImageIndices[currentPostIndex] ?? 0;
    final hasMultipleImages = currentPost.media.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Minimal progress bars
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(posts.length, (index) {
              final isViewed = index < currentPostIndex;
              final isCurrent = index == currentPostIndex;

              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isViewed
                        ? Colors.white
                        : isCurrent
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              );
            }),
          ),
        ),
        
        // Image dots for multi-image posts
        if (hasMultipleImages) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              currentPost.media.length,
              (index) => Container(
                width: index == currentImageIndex ? 6 : 4,
                height: index == currentImageIndex ? 6 : 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == currentImageIndex
                      ? Colors.white
                      : Colors.white.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Main page view for swiping through posts (vertical)
class _MediaPageView extends StatelessWidget {
  final List<Post> posts;
  final PageController pageController;
  final void Function(int) onPageChanged;
  final void Function(int, int) onImageChanged;
  final Map<int, int> currentImageIndices;

  const _MediaPageView({
    required this.posts,
    required this.pageController,
    required this.onPageChanged,
    required this.onImageChanged,
    required this.currentImageIndices,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      onPageChanged: onPageChanged,
      scrollDirection: Axis.vertical, // Vertical for posts
      itemCount: posts.length,
      itemBuilder: (context, index) {
        return _PostView(
          post: posts[index],
          postIndex: index,
          currentImageIndex: currentImageIndices[index] ?? 0,
          onImageChanged: (imageIndex) {
            onImageChanged(index, imageIndex);
          },
        );
      },
    );
  }
}

/// Single post view with media carousel (horizontal swipe)
class _PostView extends StatefulWidget {
  final Post post;
  final int postIndex;
  final int currentImageIndex;
  final void Function(int) onImageChanged;

  const _PostView({
    required this.post,
    required this.postIndex,
    required this.currentImageIndex,
    required this.onImageChanged,
  });

  @override
  State<_PostView> createState() => _PostViewState();
}

class _PostViewState extends State<_PostView> {
  late PageController _imagePageController;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController(
      initialPage: widget.currentImageIndex,
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = widget.post.media.length > 1;
    final responsive = _ResponsiveHelper(context);
    
    // Responsive caption positioning
    final captionBottomPosition = responsive.screenWidth < 375 
        ? 110.0 
        : responsive.screenWidth > 600 
            ? 160.0 
            : 130.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Media carousel (horizontal swipe for multiple images)
        if (widget.post.media.isNotEmpty)
          hasMultipleImages
              ? PageView.builder(
                  controller: _imagePageController,
                  scrollDirection: Axis.horizontal,
                  onPageChanged: widget.onImageChanged,
                  itemCount: widget.post.media.length,
                  itemBuilder: (context, index) {
                    return _MediaImage(
                      media: widget.post.media[index],
                    );
                  },
                )
              : _MediaImage(media: widget.post.media.first)
        else
          const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white,
              size: 64,
            ),
          ),

         // Caption with responsive positioning
         if (widget.post.text.isNotEmpty)
          Positioned(
            bottom: captionBottomPosition,
            left: responsive.padding * 0.8,
            right: responsive.padding * 0.8,
            child: _CaptionOverlay(
              caption: widget.post.text,
              username: widget.post.username,
            ),
          ),
      ],
    );
  }
}

/// Enhanced media image widget with subtle vignette
class _MediaImage extends StatelessWidget {
  final PostMedia media;

  const _MediaImage({required this.media});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main image
        CachedNetworkImage(
          imageUrl: 'http://localhost:8089/app-backend${media.url}',
          fit: BoxFit.cover,
          placeholder: (context, url) => 
              const Center(child: LoadingWidget()),
          errorWidget: (context, url, error) => 
              const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
              ),
        ),
        
        // Subtle vignette effect for better text readability
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.15),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
        
        // Top gradient for better header visibility
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Bottom gradient for better caption/controls visibility
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom action bar with responsive design
class _BottomActionBar extends StatelessWidget {
  final List<Post> posts;
  final int currentPostIndex;

  const _BottomActionBar({
    required this.posts,
    required this.currentPostIndex,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = _ResponsiveHelper(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: responsive.padding,
        right: responsive.padding,
        bottom: MediaQuery.of(context).padding.bottom + 
            responsive.padding * 0.8,
        top: responsive.padding * 0.8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Like button
          _ActionIconButton(
            icon: Icons.favorite_border_rounded,
            label: 'Like',
            onTap: () {
              // TODO: Implement like
            },
          ),
          
          // Comment button
          _ActionIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Comment',
            onTap: () {
              // TODO: Implement comment
            },
          ),
          
          // Share button
          _ActionIconButton(
            icon: Icons.send_rounded,
            label: 'Share',
            onTap: () {
              // TODO: Implement share
            },
          ),
          
          // Save button
          _ActionIconButton(
            icon: Icons.bookmark_border_rounded,
            label: 'Save',
            onTap: () {
              // TODO: Implement save
            },
          ),
        ],
      ),
    );
  }
}

/// Action icon button with responsive design
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = _ResponsiveHelper(context);
    final theme = Theme.of(context);
    
    // Action button icon size (larger than UI icons)
    final actionIconSize = responsive.screenWidth < 375 
        ? 22.0 
        : responsive.screenWidth > 600 
            ? 32.0 
            : 26.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: actionIconSize,
          ),
          SizedBox(height: responsive.spacing * 0.33),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal caption overlay with responsive design
class _CaptionOverlay extends StatelessWidget {
  final String caption;
  final String username;

  const _CaptionOverlay({
    required this.caption,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = _ResponsiveHelper(context);
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.padding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username - simple white text with icon
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: responsive.iconSize * 0.8,
              ),
              SizedBox(width: responsive.spacing * 0.5),
              Text(
                username,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: const [
                    Shadow(
                      color: Colors.black45,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: responsive.spacing * 0.66),
          
          // Caption text - simple white with shadow
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              height: 1.4,
              shadows: const [
                Shadow(
                  color: Colors.black45,
                  blurRadius: 8,
                ),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Error view
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 64,
          ),
          const SizedBox(height: 16),
          SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: error,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Empty view
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: Colors.white,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No media at this location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

