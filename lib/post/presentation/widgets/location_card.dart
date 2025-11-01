import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../trips/data/models/track_point.dart';

/// Card widget for displaying track point location option
class LocationCard extends StatelessWidget {
  final TrackPoint trackPoint;
  final String tripTitle;
  final bool isSelected;
  final VoidCallback onTap;

  const LocationCard({
    super.key,
    required this.trackPoint,
    required this.tripTitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _IconContainer(),
              const SizedBox(width: 16),
              Expanded(
                child: _LocationInfo(
                  trackPoint: trackPoint,
                  tripTitle: tripTitle,
                  isSelected: isSelected,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon container widget
class _IconContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.place,
        color: Colors.green[700],
        size: 24,
      ),
    );
  }
}

/// Location info widget
class _LocationInfo extends StatelessWidget {
  final TrackPoint trackPoint;
  final String tripTitle;
  final bool isSelected;

  const _LocationInfo({
    required this.trackPoint,
    required this.tripTitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                trackPoint.locationName ?? 'Track Point',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check_circle,
                color: Colors.blue[700],
                size: 20,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          tripTitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 14,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM dd, yyyy • HH:mm')
                  .format(trackPoint.timestamp),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
