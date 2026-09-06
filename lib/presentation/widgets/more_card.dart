import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/core/router/app_router.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/widgets/car_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A compact row used for the "similar cars" list on the details page.
///
/// It renders a real car from the repository. The previous version fabricated
/// entries by appending '-1' to the model name and adding 100 to every number.
class MoreCard extends StatelessWidget {
  final Car car;

  const MoreCard({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      label: '${car.model}, \$${car.pricePerDay.toStringAsFixed(0)} per day',
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        // Replaces the current detail page, so tapping through several
        // similar cars does not build a deep back stack.
        onTap: () => context.pushReplacement(Routes.carDetailsFor(car.id)),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                height: 48,
                child: CarImage(imageUrl: car.imageUrl, fit: BoxFit.contain),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      car.model,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${car.rangeLabel} · ${car.capacityLabel}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '\$${car.pricePerDay.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: scheme.primary),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
