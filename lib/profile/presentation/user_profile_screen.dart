import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/app/theme/colors.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/core/widgets/app_avatar.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/retry_widget.dart';
import 'package:travel_diary_frontend/profile/presentation/controllers/profile_controller.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/follow_controller.dart';

/// Screen to display any user's profile (not just current user)
class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).loadUserById(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    
    final user = profileState.users[widget.userId];
    // Compare user IDs as strings to handle UUID format differences
    final isCurrentUser = authState.user?.id != null && 
                          widget.userId.isNotEmpty &&
                          authState.user!.id.toString() == widget.userId.toString();
    
    // Only watch follow state if not current user and userId is valid UUID
    final followState = !isCurrentUser && 
                       RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(widget.userId)
        ? ref.watch(followControllerProvider(widget.userId))
        : FollowState();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          user?.username ?? 'Profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        elevation: 0,
      ),
      body: _buildBody(context, user, isCurrentUser, followState, profileState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    user,
    bool isCurrentUser,
    FollowState followState,
    ProfileState profileState,
  ) {
    if (profileState.isLoading && user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (profileState.error != null && user == null) {
      return RetryWidget(
        message: profileState.error!,
        onRetry: () {
          ref.read(profileControllerProvider.notifier).loadUserById(widget.userId);
        },
      );
    }

    if (user == null) {
      return const EmptyState(
        icon: Icons.person_outline,
        title: 'User not found',
        message: 'This user does not exist or has been deleted.',
      );
    }

    return CustomScrollView(
      slivers: [
        // Profile Header
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight,
                  AppColors.primaryDark,
                  AppColors.secondaryLight,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: AppAvatar(
                        imageUrl: _buildFullAvatarUrl(user.avatarUrl),
                        name: user.username,
                        size: 100,
                        showBorder: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Username
                    Text(
                      user.username,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (user.bio != null && user.bio!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.bio!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          context,
                          '${user.tripsCount}',
                          'Trips',
                          Colors.white,
                        ),
                        _buildStatItem(
                          context,
                          '${user.stepsCount}',
                          'Places',
                          Colors.white,
                        ),
                        _buildStatItem(
                          context,
                          '${user.followersCount}',
                          'Followers',
                          Colors.white,
                        ),
                        _buildStatItem(
                          context,
                          '${user.followingCount}',
                          'Following',
                          Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Follow/Unfollow button or Edit Profile button
                    if (isCurrentUser)
                      ElevatedButton.icon(
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: followState.isLoading
                              ? null
                              : () async {
                                  try {
                                    await ref
                                        .read(
                                          followControllerProvider(widget.userId)
                                              .notifier,
                                        )
                                        .toggleFollow();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to ${followState.isFollowing ? 'unfollow' : 'follow'} user. Please try again.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: followState.isFollowing
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white,
                            foregroundColor: followState.isFollowing
                                ? Colors.white
                                : AppColors.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: followState.isFollowing
                                ? const BorderSide(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: followState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  followState.isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Content (placeholder for now - can add posts, trips, etc.)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posts & Trips',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text('Posts and trips will be displayed here'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    Color textColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor.withOpacity(0.9),
              ),
        ),
      ],
    );
  }

  String? _buildFullAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    if (avatarUrl.startsWith('http')) return avatarUrl;
    if (avatarUrl.startsWith('/')) {
      return 'http://localhost:8089/app-backend$avatarUrl';
    }
    return 'http://localhost:8089/app-backend/$avatarUrl';
  }
}

