import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travel_diary_frontend/app/theme/colors.dart';
import 'package:travel_diary_frontend/auth/presentation/controllers/auth_controller.dart';
import 'package:travel_diary_frontend/core/data/fake_data.dart';
import 'package:travel_diary_frontend/core/widgets/app_avatar.dart';
import 'controllers/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load current user profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileControllerProvider.notifier).loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    
    // Use real user data if available, fallback to auth user, then fake data
    final user = profileState.currentUser ?? 
                 authState.user ?? 
                 FakeData.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(profileControllerProvider.notifier).refreshProfile();
        },
        child: profileState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Avatar and basic info
            AppAvatar(
              imageUrl: user.avatarUrl,
              name: user.username,
              size: 100,
              showBorder: true,
            ),

            const SizedBox(height: 16),

            Text(
              user.username,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 4),

            Text(
              user.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),

            if (user.bio != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  user.bio!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat(
                    context,
                    value: user.tripsCount.toString(),
                    label: 'Trips',
                    isDark: true,
                  ),
                  _buildDivider(),
                  _buildStat(
                    context,
                    value: user.stepsCount.toString(),
                    label: 'Steps',
                    isDark: true,
                  ),
                  _buildDivider(),
                  _buildStat(
                    context,
                    value: user.followersCount.toString(),
                    label: 'Followers',
                    isDark: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/profile/edit');
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share profile coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share Profile'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Menu items
            _buildMenuItem(
              context,
              icon: Icons.visibility_outlined,
              title: 'Default Visibility',
              subtitle: user.defaultVisibility,
              onTap: () {
                _showVisibilitySheet(context);
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.bookmark_outline,
              title: 'Saved Posts',
              onTap: () {},
            ),

            _buildMenuItem(
              context,
              icon: Icons.favorite_outline,
              title: 'Liked Posts',
              onTap: () {},
            ),

            _buildMenuItem(
              context,
              icon: Icons.people_outline,
              title: 'Following',
              subtitle: '${user.followingCount} users',
              onTap: () {},
            ),

            _buildMenuItem(
              context,
              icon: Icons.group_outlined,
              title: 'Followers',
              subtitle: '${user.followersCount} users',
              onTap: () {},
            ),

            const Divider(height: 32),


            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              titleColor: Theme.of(context).colorScheme.error,
              onTap: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/auth/login');
                }
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, {
    required String value,
    required String label,
    bool isDark = false,
  }) {
    final textColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: textColor.withOpacity(0.8),
              ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor),
      title: Text(
        title,
        style: titleColor != null
            ? TextStyle(color: titleColor)
            : null,
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showVisibilitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Visibility',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Set the default visibility for your new trips and posts',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Public'),
              subtitle: const Text('Everyone can see'),
              trailing: const Icon(Icons.check),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Friends'),
              subtitle: const Text('Only friends can see'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Private'),
              subtitle: const Text('Only you can see'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

