import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/post_controller.dart';

/// State for create post screen
class CreatePostState {
  final List<XFile> selectedImages;
  final String caption;
  final bool isUploading;
  final String? error;

  const CreatePostState({
    this.selectedImages = const [],
    this.caption = '',
    this.isUploading = false,
    this.error,
  });

  CreatePostState copyWith({
    List<XFile>? selectedImages,
    String? caption,
    bool? isUploading,
    String? error,
  }) {
    return CreatePostState(
      selectedImages: selectedImages ?? this.selectedImages,
      caption: caption ?? this.caption,
      isUploading: isUploading ?? this.isUploading,
      error: error,
    );
  }
}

/// Create post screen with image picker functionality
class CreatePostScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> locationData;

  const CreatePostScreen({
    super.key,
    required this.locationData,
  });

  @override
  ConsumerState<CreatePostScreen> createState() => 
      _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _captionController = 
      TextEditingController();
  
  CreatePostState _state = const CreatePostState();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _updateState(CreatePostState newState) {
    if (mounted) {
      setState(() => _state = newState);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = 
          await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        _updateState(_state.copyWith(
          selectedImages: [..._state.selectedImages, ...images],
          error: null,
        ));
      }
    } catch (e) {
      log('Error picking images: $e');
      _updateState(_state.copyWith(
        error: 'Failed to pick images: $e',
      ));
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        _updateState(_state.copyWith(
          selectedImages: [..._state.selectedImages, image],
          error: null,
        ));
      }
    } catch (e) {
      log('Error taking photo: $e');
      _updateState(_state.copyWith(
        error: 'Failed to take photo: $e',
      ));
    }
  }

  void _removeImage(int index) {
    final updatedImages = List<XFile>.from(_state.selectedImages)
      ..removeAt(index);
    _updateState(_state.copyWith(selectedImages: updatedImages));
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => _MediaPickerBottomSheet(
        onGalleryTap: () {
          context.pop();
          _pickImages();
        },
        onCameraTap: () {
          context.pop();
          _pickImageFromCamera();
        },
      ),
    );
  }

  Future<void> _handlePostCreation() async {
    if (_state.selectedImages.isEmpty) {
      _updateState(_state.copyWith(
        error: 'Please select at least one image',
      ));
      return;
    }

    _updateState(_state.copyWith(
      isUploading: true,
      error: null,
    ));

    try {
      // Extract location data
      final latitude = 
          widget.locationData['latitude'] as double? ?? 0.0;
      final longitude = 
          widget.locationData['longitude'] as double? ?? 0.0;
      final trackPointId = 
          widget.locationData['trackPointId'] as int?;

      // Convert XFile list to File list
      final images = _state.selectedImages
          .map((xFile) => File(xFile.path))
          .toList();

      // Get trip ID from location data
      final tripId = 
          widget.locationData['tripId'] as String? ?? 
          'unknown-trip-id'; 

      log('Creating post with ${images.length} images');

      final controller = ref.read(postControllerProvider.notifier);
      final post = await controller.createPost(
        tripId: tripId,
        trackPointId: trackPointId,
        latitude: latitude,
        longitude: longitude,
        caption: _state.caption,
        visibility: 'PUBLIC',
        images: images,
      );

      if (!mounted) return;

      if (post != null) {
        log('Post created successfully: ${post.id}');
        // Navigate back to map
        if (mounted) context.go('/map');
      } else {
        final error = 
            ref.read(postControllerProvider).error ?? 
            'Failed to create post';
        _updateState(_state.copyWith(
          isUploading: false,
          error: error,
        ));
      }
    } catch (e) {
      log('Error creating post: $e');
      _updateState(_state.copyWith(
        isUploading: false,
        error: 'Failed to create post: $e',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationType = widget.locationData['type'] as String;
    final latitude = widget.locationData['latitude'] as double?;
    final longitude = widget.locationData['longitude'] as double?;
    final address = widget.locationData['address'] as String? ?? 
        'Unknown Location';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_state.isUploading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _handlePostCreation,
              child: const Text(
                'Post',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error display (following cursorRules)
            if (_state.error != null)
              _ErrorDisplay(error: _state.error!),

            // Location Info Card
            _LocationInfoCard(
              locationType: locationType,
              address: address,
              latitude: latitude,
              longitude: longitude,
            ),

            // Media Section
            _MediaSection(
              selectedImages: _state.selectedImages,
              onAddPhotosTap: _showMediaPickerOptions,
              onRemoveImage: _removeImage,
            ),

            const SizedBox(height: 24),

            // Caption Section
            _CaptionSection(
              controller: _captionController,
              onChanged: (value) {
                _updateState(_state.copyWith(caption: value));
              },
            ),

            const SizedBox(height: 24),

            // Info card
            const _InfoCard(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Error display widget following cursorRules
class _ErrorDisplay extends StatelessWidget {
  final String error;

  const _ErrorDisplay({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: SelectableText.rich(
        TextSpan(
          children: [
            WidgetSpan(
              child: Icon(
                Icons.error_outline,
                color: Colors.red[700],
                size: 20,
              ),
            ),
            const WidgetSpan(
              child: SizedBox(width: 8),
            ),
            TextSpan(
              text: error,
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Location info card widget
class _LocationInfoCard extends StatelessWidget {
  final String locationType;
  final String address;
  final double? latitude;
  final double? longitude;

  const _LocationInfoCard({
    required this.locationType,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                locationType == 'current'
                    ? Icons.my_location
                    : Icons.location_on,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected Location',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${latitude?.toStringAsFixed(6)}, '
            '${longitude?.toStringAsFixed(6)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Media section widget
class _MediaSection extends StatelessWidget {
  final List<XFile> selectedImages;
  final VoidCallback onAddPhotosTap;
  final void Function(int) onRemoveImage;

  const _MediaSection({
    required this.selectedImages,
    required this.onAddPhotosTap,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Media',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: onAddPhotosTap,
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: const Text('Add Photos'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (selectedImages.isEmpty)
            _EmptyMediaState(onTap: onAddPhotosTap)
          else
            _MediaGrid(
              selectedImages: selectedImages,
              onRemoveImage: onRemoveImage,
            ),
        ],
      ),
    );
  }
}

/// Empty media state widget
class _EmptyMediaState extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyMediaState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to add photos or videos',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Media grid widget
class _MediaGrid extends StatelessWidget {
  final List<XFile> selectedImages;
  final void Function(int) onRemoveImage;

  const _MediaGrid({
    required this.selectedImages,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: selectedImages.length,
      itemBuilder: (context, index) {
        return _MediaGridItem(
          image: selectedImages[index],
          onRemove: () => onRemoveImage(index),
        );
      },
    );
  }
}

/// Media grid item widget
class _MediaGridItem extends StatelessWidget {
  final XFile image;
  final VoidCallback onRemove;

  const _MediaGridItem({
    required this.image,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(image.path),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(
                  Icons.error_outline,
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Caption section widget
class _CaptionSection extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  const _CaptionSection({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caption',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Write a caption for your post...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.blue,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info card widget
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Backend API for post creation not yet implemented. '
              'This is a preview of the UI and image picker functionality.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Media picker bottom sheet widget
class _MediaPickerBottomSheet extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;

  const _MediaPickerBottomSheet({
    required this.onGalleryTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.blue,
              ),
              title: const Text('Choose from gallery'),
              onTap: onGalleryTap,
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: Colors.blue,
              ),
              title: const Text('Take a photo'),
              onTap: onCameraTap,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
