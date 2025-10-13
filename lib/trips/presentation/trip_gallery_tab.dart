import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:travel_diary_frontend/core/widgets/app_network_image.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/trips/data/models/media.dart';
import 'package:travel_diary_frontend/trips/data/models/step_post.dart';

class TripGalleryTab extends StatelessWidget {
  final List<StepPost> steps;

  const TripGalleryTab({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    // Collect all photos from all steps
    final allPhotos = <Media>[];
    for (final step in steps) {
      allPhotos.addAll(step.photos);
    }

    if (allPhotos.isEmpty) {
      return const EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No Photos Yet',
        message: 'Add steps with photos to see them in the gallery',
      );
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.all(8),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: allPhotos.length,
      itemBuilder: (context, index) {
        final photo = allPhotos[index];
        
        return GestureDetector(
          onTap: () {
            _showPhotoViewer(context, allPhotos, index);
          },
          child: Hero(
            tag: 'photo_${photo.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppNetworkImage(
                imageUrl: photo.url,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPhotoViewer(BuildContext context, List<Media> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _PhotoViewer extends StatefulWidget {
  final List<Media> photos;
  final int initialIndex;

  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: 'photo_${photo.id}',
                child: AppNetworkImage(
                  imageUrl: photo.url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

