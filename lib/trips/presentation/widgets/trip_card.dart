import 'package:flutter/material.dart';
import 'package:travel_diary_frontend/core/utils/date_time.dart';
import 'package:travel_diary_frontend/core/widgets/app_network_image.dart';
import 'package:travel_diary_frontend/core/widgets/visibility_badge.dart';
import 'package:travel_diary_frontend/trips/data/models/trip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              // Cover Image with full height
              AspectRatio(
                aspectRatio: 16 / 10,
                child: trip.coverUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          AppNetworkImage(
                            imageUrl: trip.coverUrl!,
                            width: double.infinity,
                          ),
                          // Gradient overlay - stronger at bottom
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.2),
                                  Colors.black.withOpacity(0.7),
                                ],
                                stops: const [0.3, 1.0],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue[100]!,
                              Colors.purple[100]!,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.image_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
                  
              // Visibility badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getVisibilityIcon(trip.visibility),
                        size: 12,
                        color: _getVisibilityColor(trip.visibility),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trip.visibility.toLowerCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getVisibilityColor(trip.visibility),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Enhanced Actions menu
              if (onEdit != null || onDelete != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      icon: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_horiz,
                          color: Colors.grey[800],
                          size: 16,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      offset: const Offset(-10, 35),
                      color: Colors.white,
                      onSelected: (value) {
                        if (value == 'edit' && onEdit != null) {
                          onEdit!();
                        } else if (value == 'delete' && onDelete != null) {
                          onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            height: 42,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (onEdit != null && onDelete != null)
                          const PopupMenuDivider(height: 1),
                        if (onDelete != null)
                          PopupMenuItem(
                            value: 'delete',
                            height: 42,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red[700],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Trip Info - Positioned at bottom over the image
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title - White text on dark gradient
                      Text(
                        trip.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black38,
                              offset: Offset(0, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Date Range with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              DateTimeUtils.formatDateRange(trip.startDate, trip.endDate),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(0, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Stats with semi-transparent background
                      Row(
                        children: [
                          _buildStat(
                            context,
                            icon: Icons.place,
                            label: '${trip.stats.stepsCount}',
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          _buildStat(
                            context,
                            icon: Icons.photo_camera,
                            label: '${trip.stats.photosCount}',
                            color: Colors.white,
                          ),
                          if (trip.stats.distanceKm > 0) ...[
                            const SizedBox(width: 12),
                            _buildStat(
                              context,
                              icon: Icons.route,
                              label: '${trip.stats.distanceKm.toStringAsFixed(0)}km',
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              shadows: const [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVisibilityIcon(String visibility) {
    switch (visibility.toUpperCase()) {
      case 'PUBLIC':
        return Icons.public;
      case 'FRIENDS':
        return Icons.people;
      case 'PRIVATE':
        return Icons.lock;
      default:
        return Icons.people;
    }
  }

  Color _getVisibilityColor(String visibility) {
    switch (visibility.toUpperCase()) {
      case 'PUBLIC':
        return Colors.green;
      case 'FRIENDS':
        return Colors.blue;
      case 'PRIVATE':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  VisibilityType _getVisibilityType(String visibility) {
    switch (visibility.toUpperCase()) {
      case 'PUBLIC':
        return VisibilityType.public;
      case 'FRIENDS':
        return VisibilityType.friends;
      case 'PRIVATE':
        return VisibilityType.private;
      default:
        return VisibilityType.friends;
    }
  }
}

