import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:travel_diary_frontend/app/theme/colors.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius,
  });

  const SkeletonLoader.card({
    super.key,
    this.width = double.infinity,
    this.height = 200,
  }) : borderRadius = const BorderRadius.all(Radius.circular(16));

  const SkeletonLoader.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        borderRadius = null;

  const SkeletonLoader.text({
    super.key,
    this.width = 100,
    this.height = 16,
  }) : borderRadius = const BorderRadius.all(Radius.circular(4));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBase,
      highlightColor: isDark ? AppColors.shimmerHighlightDark : AppColors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
        ),
      ),
    );
  }
}

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonLoader.circle(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader.text(width: 120),
                      const SizedBox(height: 4),
                      SkeletonLoader.text(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SkeletonLoader.text(width: double.infinity),
            const SizedBox(height: 8),
            SkeletonLoader.text(width: MediaQuery.of(context).size.width * 0.7),
            const SizedBox(height: 16),
            const SkeletonLoader.card(height: 250),
            const SizedBox(height: 12),
            Row(
              children: [
                SkeletonLoader.text(width: 60),
                const SizedBox(width: 16),
                SkeletonLoader.text(width: 60),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TripCardSkeleton extends StatelessWidget {
  const TripCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader.card(height: 180),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader.text(width: 200),
                const SizedBox(height: 8),
                SkeletonLoader.text(width: 120, height: 14),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SkeletonLoader.text(width: 80, height: 12),
                    const SizedBox(width: 16),
                    SkeletonLoader.text(width: 60, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

