import 'package:flutter/material.dart';
import 'package:travel_diary_frontend/core/utils/date_time.dart';
import 'package:travel_diary_frontend/core/widgets/app_network_image.dart';
import 'package:travel_diary_frontend/core/widgets/empty_state.dart';
import 'package:travel_diary_frontend/trips/data/models/step_post.dart';

class TripTimelineTab extends StatelessWidget {
  final List<StepPost> steps;

  const TripTimelineTab({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const EmptyState(
        icon: Icons.timeline_outlined,
        title: 'No Steps Yet',
        message: 'Add your first step to start documenting this trip',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isFirst = index == 0;
        final isLast = index == steps.length - 1;

        return _StepCard(
          step: step,
          isFirst: isFirst,
          isLast: isLast,
        );
      },
    );
  }
}

class _StepCard extends StatefulWidget {
  final StepPost step;
  final bool isFirst;
  final bool isLast;

  const _StepCard({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasLongText = (widget.step.text?.length ?? 0) > 200;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        SizedBox(
          width: 60,
          child: Column(
            children: [
              if (!widget.isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              if (!widget.isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Text(
                      DateTimeUtils.formatDateTime(widget.step.takenAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),

                    const SizedBox(height: 8),

                    // Title
                    if (widget.step.title != null) ...[
                      Text(
                        widget.step.title!,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Text
                    if (widget.step.text != null) ...[
                      Text(
                        widget.step.text!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: _isExpanded ? null : 4,
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
                      const SizedBox(height: 12),
                    ],

                    // Photos
                    if (widget.step.photos.isNotEmpty) ...[
                      _buildPhotoGrid(),
                      const SizedBox(height: 12),
                    ],

                    // Location
                    if (widget.step.location.name != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.step.location.name}${widget.step.location.city != null ? ', ${widget.step.location.city}' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid() {
    final photos = widget.step.photos;

    if (photos.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: photos[0].ratio,
          child: AppNetworkImage(
            imageUrl: photos[0].url,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length > 4 ? 4 : photos.length,
      itemBuilder: (context, index) {
        if (index == 3 && photos.length > 4) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  imageUrl: photos[index].url,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '+${photos.length - 4}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ],
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AppNetworkImage(
            imageUrl: photos[index].url,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

