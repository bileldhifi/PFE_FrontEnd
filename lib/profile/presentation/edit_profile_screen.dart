import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/colors.dart';
import '../../auth/data/models/user.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_avatar.dart';
import 'controllers/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final User user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedVisibility = 'FRIENDS';
  String? _selectedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _usernameController.text = widget.user.username;
    _bioController.text = widget.user.bio ?? '';
    _selectedVisibility = widget.user.defaultVisibility;
    _selectedAvatarUrl = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(profileControllerProvider.notifier).clearError();
      
      await ref.read(profileControllerProvider.notifier).updateProfile(
        username: _usernameController.text,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        avatarUrl: _selectedAvatarUrl,
        defaultVisibility: _selectedVisibility,
      );
      
      if (mounted) {
        final profileState = ref.read(profileControllerProvider);
        if (profileState.error == null && profileState.successMessage != null) {
          _showSuccessDialog();
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: Theme.of(context).colorScheme.primary,
          size: 48,
        ),
        title: const Text('Profile Updated'),
        content: const Text('Your profile has been updated successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop(); // Go back to profile screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Update Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: profileState.isUpdating ? null : _handleSave,
            child: profileState.isUpdating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Profile picture section
                Center(
                  child: Column(
                    children: [
                      AppAvatar(
                        imageUrl: _selectedAvatarUrl,
                        name: _usernameController.text,
                        size: 100,
                        showBorder: true,
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _showAvatarPicker(),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Change Photo'),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Username field
                AppTextField(
                  label: 'Username',
                  hint: 'Enter your username',
                  controller: _usernameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) => Validators.required(value, fieldName: 'Username'),
                  enabled: !profileState.isUpdating,
                ),
                
                const SizedBox(height: 20),
                
                // Bio field
                AppTextField(
                  label: 'Bio',
                  hint: 'Tell us about yourself',
                  controller: _bioController,
                  prefixIcon: const Icon(Icons.description_outlined),
                  maxLines: 3,
                  enabled: !profileState.isUpdating,
                ),
                
                const SizedBox(height: 20),
                
                // Default visibility section
                Text(
                  'Default Visibility',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildVisibilitySelector(),
                
                const SizedBox(height: 20),
                
                // Error display
                if (profileState.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.error,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profileState.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Save button
                ElevatedButton(
                  onPressed: profileState.isUpdating ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: profileState.isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                ),
                
                const SizedBox(height: 24),
                
                // Delete account button
                TextButton.icon(
                  onPressed: profileState.isUpdating ? null : _showDeleteAccountDialog,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Public'),
          subtitle: const Text('Everyone can see your posts'),
          value: 'PUBLIC',
          groupValue: _selectedVisibility,
          onChanged: (value) {
            setState(() {
              _selectedVisibility = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('Friends'),
          subtitle: const Text('Only friends can see your posts'),
          value: 'FRIENDS',
          groupValue: _selectedVisibility,
          onChanged: (value) {
            setState(() {
              _selectedVisibility = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('Private'),
          subtitle: const Text('Only you can see your posts'),
          value: 'PRIVATE',
          groupValue: _selectedVisibility,
          onChanged: (value) {
            setState(() {
              _selectedVisibility = value!;
            });
          },
        ),
      ],
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Avatar',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Preset avatars
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final avatarUrl = 'https://i.pravatar.cc/150?img=${index + 1}';
                final isSelected = _selectedAvatarUrl == avatarUrl;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatarUrl = avatarUrl;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: AppAvatar(
                      imageUrl: avatarUrl,
                      name: '',
                      size: 60,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_outlined,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(profileControllerProvider.notifier).deleteAccount();
              if (mounted) {
                // Navigate to login screen after account deletion
                context.go('/auth/login');
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
