import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/theme/colors.dart';
import '../../auth/data/models/user.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_avatar.dart';
import 'controllers/profile_controller.dart';
import '../data/repo/avatar_repository.dart';

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
  final _avatarRepository = AvatarRepository();
  final _imagePicker = ImagePicker();
  
  String _selectedVisibility = 'FRIENDS';
  File? _selectedImageFile;
  String? _currentAvatarUrl;
  bool _removeAvatarRequested = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _usernameController.text = widget.user.username;
    _bioController.text = widget.user.bio ?? '';
    _selectedVisibility = widget.user.defaultVisibility;
    _currentAvatarUrl = _buildFullAvatarUrl(widget.user.avatarUrl);
  }

  String? _buildFullAvatarUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    
    // If it's already a full URL, return as is
    if (avatarUrl.startsWith('http')) return avatarUrl;
    
    // If it's a relative path, convert to full URL
    if (avatarUrl.startsWith('/')) {
      return 'http://localhost:8089/app-backend$avatarUrl';
    }
    
    // If it doesn't start with /, add it
    return 'http://localhost:8089/app-backend/$avatarUrl';
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
      
      try {
        print('Starting profile save...');
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // Handle avatar changes
        if (_removeAvatarRequested) {
          // Remove avatar from backend
          try {
            await _avatarRepository.deleteAvatar();
          } catch (avatarError) {
            // If avatar removal fails, show error and return
            if (mounted) {
              Navigator.of(context).pop(); // Close loading dialog
              _showErrorDialog('Failed to remove avatar: ${avatarError.toString()}');
              return;
            }
          }
        } else if (_selectedImageFile != null) {
          // Upload new avatar
          try {
            final newAvatarUrl = await _avatarRepository.uploadAvatar(_selectedImageFile!);
            _currentAvatarUrl = newAvatarUrl;
          } catch (avatarError) {
            // If avatar upload fails, show error and return
            if (mounted) {
              Navigator.of(context).pop(); // Close loading dialog
              _showErrorDialog('Failed to upload avatar: ${avatarError.toString()}');
              return;
            }
          }
        }
        
        // Update profile
        print('Updating profile...');
        await ref.read(profileControllerProvider.notifier).updateProfile(
          username: _usernameController.text,
          bio: _bioController.text.isNotEmpty ? _bioController.text : null,
          defaultVisibility: _selectedVisibility,
        );
        print('Profile updated successfully');
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Show success and go back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          // Go back to profile screen
          context.pop();
        }
      } catch (e) {
        print('Error during profile save: $e');
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
          _showErrorDialog(e.toString());
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
                
                // Avatar preview section
                Center(
                  child: Column(
                    children: [
                      AppAvatar(
                        imageUrl: _removeAvatarRequested ? null : (_selectedImageFile != null ? null : (_currentAvatarUrl ?? _buildFullAvatarUrl(widget.user.avatarUrl))),
                        imageFile: _removeAvatarRequested ? null : _selectedImageFile,
                        name: widget.user.username,
                        size: 120,
                        showBorder: true,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Profile Picture',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _showImagePicker,
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

  Future<void> _showImagePicker() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            // Only show remove option if there's an existing avatar and not already requested to remove
            if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty && !_removeAvatarRequested)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Avatar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatarPreview();
                },
              ),
            // Show restore option if removal was requested
            if (_removeAvatarRequested)
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.green),
                title: const Text('Restore Avatar', style: TextStyle(color: Colors.green)),
                onTap: () {
                  Navigator.pop(context);
                  _restoreAvatarPreview();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected! Press Save to upload.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeAvatarPreview() {
    setState(() {
      _removeAvatarRequested = true;
      _selectedImageFile = null; // Clear any selected image
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avatar will be removed when you save changes.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _restoreAvatarPreview() {
    setState(() {
      _removeAvatarRequested = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avatar restored.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

}
