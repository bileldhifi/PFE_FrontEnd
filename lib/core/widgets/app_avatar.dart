import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:travel_diary_frontend/app/theme/colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String name;
  final double size;
  final bool showBorder;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.imageFile,
    required this.name,
    this.size = 40,
    this.showBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: ClipOval(
        child: imageFile != null
            ? Image.file(
                imageFile!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(initials),
              )
            : imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(initials),
                    errorWidget: (context, url, error) => _buildPlaceholder(initials),
                  )
                : _buildPlaceholder(initials),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildPlaceholder(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getGradientForName(name),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  LinearGradient _getGradientForName(String name) {
    final hash = name.hashCode.abs();
    final gradients = [
      AppColors.primaryGradient,
      AppColors.sunsetGradient,
      AppColors.adventureGradient,
      const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
      ),
      const LinearGradient(
        colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
      ),
      const LinearGradient(
        colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      ),
    ];
    return gradients[hash % gradients.length];
  }
}

