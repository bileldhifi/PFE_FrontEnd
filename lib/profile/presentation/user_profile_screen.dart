import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:travel_diary_frontend/app/theme/colors.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/auth/data/models/user.dart';
import 'package:travel_diary_frontend/core/widgets/app_avatar.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/core/widgets/retry_widget.dart';
import 'package:travel_diary_frontend/profile/presentation/controllers/profile_controller.dart';
import 'package:travel_diary_frontend/profile/data/dtos/profile_travel_stats.dart';
import 'package:travel_diary_frontend/profile/presentation/controllers/profile_travel_stats_provider.dart';
import 'package:travel_diary_frontend/social/presentation/controllers/follow_controller.dart';
import 'package:travel_diary_frontend/messages/presentation/controllers/conversation_list_controller.dart';

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

    final memberSince = DateFormat('MMM yyyy').format(user.createdAt);

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
                    Text(
                      user.username,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const SizedBox(height: 12),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.32),
                        ),
                      ),
                      child: Text(
                        'Member since $memberSince',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
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
                    ProfileStatsSection(user: user),
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
                      Row(
                        children: [
                          Expanded(
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
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () async {
                              final conversation = await ref
                                  .read(conversationListControllerProvider.notifier)
                                  .ensureConversation(widget.userId);
                              if (!mounted) return;
                              context.push(
                                '/messages/${conversation.id}',
                                extra: {
                                  'otherUserId': conversation.otherUserId,
                                  'otherUsername': conversation.otherUsername,
                                  'otherAvatarUrl': conversation.otherAvatarUrl,
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              side: const BorderSide(color: Colors.white, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.message_outlined),
                          ),
                        ],
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

  String? _buildFullAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    if (avatarUrl.startsWith('http')) return avatarUrl;
    if (avatarUrl.startsWith('/')) {
      return 'http://localhost:8089/app-backend$avatarUrl';
    }
    return 'http://localhost:8089/app-backend/$avatarUrl';
  }
}

class ProfileStatsSection extends ConsumerWidget {
  const ProfileStatsSection({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileTravelStatsProvider(user.id));

    return statsAsync.when(
      data: (stats) => ProfileStatsGrid(user: user, stats: stats),
      loading: () => const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SelectableText.rich(
          TextSpan(
            text: 'Failed to load travel stats.\n',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: '$error',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ProfileStatsGrid extends StatelessWidget {
  const ProfileStatsGrid({
    required this.user,
    required this.stats,
  });

  final User user;
  final ProfileTravelStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = NumberFormat.compact();

    final cards = [
      _ProfileStatCardData(
        icon: Icons.flight_takeoff_outlined,
        label: 'Trips completed',
        value: compact.format(stats.tripsCount),
        accentColor: const Color(0xFF3498FF),
      ),
      _ProfileStatCardData(
        icon: Icons.route_outlined,
        label: 'Distance travelled',
        value: _formatDistance(stats.totalDistanceKm),
        accentColor: const Color(0xFFB388FF),
      ),
      _ProfileStatCardData(
        icon: Icons.public_outlined,
        label: 'Countries visited',
        value: compact.format(stats.countriesVisited),
        accentColor: const Color(0xFF2ECC71),
      ),
      _ProfileStatCardData(
        icon: Icons.location_city_outlined,
        label: 'Cities explored',
        value: compact.format(stats.citiesVisited),
        accentColor: const Color(0xFF40C4FF),
      ),
      _ProfileStatCardData(
        icon: Icons.camera_alt_outlined,
        label: 'Photos captured',
        value: compact.format(stats.photosCount),
        accentColor: const Color(0xFF7A6CFF),
      ),
      _ProfileStatCardData(
        icon: Icons.post_add_outlined,
        label: 'Posts shared',
        value: compact.format(stats.postsCount),
        accentColor: const Color(0xFFFF9A62),
      ),
      _ProfileStatCardData(
        icon: Icons.people_alt_outlined,
        label: 'Followers',
        value: compact.format(user.followersCount),
        accentColor: const Color(0xFFFFB74D),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 520;
        final crossAxisCount = isWide ? 3 : 2;
        final spacing = 12.0;
        final availableWidth = constraints.maxWidth -
            spacing * (crossAxisCount - 1);
        final cardWidth = availableWidth / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards.map((card) {
            return SizedBox(
              width: cardWidth,
              child: _ProfileStatCard(
                data: card,
                theme: theme,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatDistance(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k km';
    }
    return '${value.toStringAsFixed(1)} km';
  }
}

class _ProfileStatCardData {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _ProfileStatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.data,
    required this.theme,
  });

  final _ProfileStatCardData data;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface.withOpacity(0.98),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: data.accentColor.withOpacity(0.16),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: data.accentColor.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                data.icon,
                color: data.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              data.value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

