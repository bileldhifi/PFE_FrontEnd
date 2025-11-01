import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;

/// Card widget for displaying current location option
class CurrentLocationCard extends StatelessWidget {
  final geo.Position position;
  final bool isSelected;
  final VoidCallback onTap;

  const CurrentLocationCard({
    super.key,
    required this.position,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  position: position,
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
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.my_location,
        color: Colors.blue[700],
        size: 24,
      ),
    );
  }
}

/// Location info widget
class _LocationInfo extends StatelessWidget {
  final geo.Position position;
  final bool isSelected;

  const _LocationInfo({
    required this.position,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Current Location',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
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
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.gps_fixed,
              size: 14,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              'Accuracy: ${position.accuracy.toStringAsFixed(0)}m',
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
