import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      highlightColor: colorScheme.surfaceContainerHighest.withOpacity(0.2),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  final int itemCount;
  const ListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            const Skeleton(width: 50, height: 50, borderRadius: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton(width: 150, height: 16),
                  const SizedBox(height: 8),
                  Skeleton(width: MediaQuery.of(context).size.width * 0.4, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(width: double.infinity, height: 120, borderRadius: 16),
        SizedBox(height: 12),
        Skeleton(width: 200, height: 20),
        SizedBox(height: 8),
        Skeleton(width: 150, height: 14),
      ],
    );
  }
}
