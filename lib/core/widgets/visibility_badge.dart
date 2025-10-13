import 'package:flutter/material.dart';
import 'package:travel_diary_frontend/app/theme/colors.dart';

enum VisibilityType { public, friends, private }

class VisibilityBadge extends StatelessWidget {
  final VisibilityType visibility;
  final bool showLabel;

  const VisibilityBadge({
    super.key,
    required this.visibility,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(visibility);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: config.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 14,
            color: config.color,
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              config.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: config.color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  _VisibilityConfig _getConfig(VisibilityType type) {
    switch (type) {
      case VisibilityType.public:
        return _VisibilityConfig(
          icon: Icons.public,
          label: 'Public',
          color: AppColors.visibilityPublic,
        );
      case VisibilityType.friends:
        return _VisibilityConfig(
          icon: Icons.people,
          label: 'Friends',
          color: AppColors.visibilityFriends,
        );
      case VisibilityType.private:
        return _VisibilityConfig(
          icon: Icons.lock,
          label: 'Private',
          color: AppColors.visibilityPrivate,
        );
    }
  }
}

class _VisibilityConfig {
  final IconData icon;
  final String label;
  final Color color;

  _VisibilityConfig({
    required this.icon,
    required this.label,
    required this.color,
  });
}

