import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Placeholder shown while cars load. A shape-matched skeleton avoids the
/// layout jump a centred spinner causes when the real content arrives.
class CarCardSkeleton extends StatelessWidget {
  const CarCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: scheme.surfaceContainerHighest,
      highlightColor: scheme.surfaceContainer,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(height: 140, width: double.infinity),
              const SizedBox(height: AppSpacing.md),
              _box(height: 22, width: 180),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _box(height: 24, width: 80),
                  const SizedBox(width: AppSpacing.sm),
                  _box(height: 24, width: 80),
                  const SizedBox(width: AppSpacing.sm),
                  _box(height: 24, width: 70),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _box(height: 26, width: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box({required double height, required double width}) {
    return Container(
      height: height,
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.smAll,
      ),
    );
  }
}
