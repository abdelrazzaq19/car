import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/pages/car_details_page.dart';
import 'package:car_rental_app/presentation/widgets/car_image.dart';
import 'package:car_rental_app/presentation/widgets/spec_chip.dart';
import 'package:flutter/material.dart';

class CarCard extends StatelessWidget {
  final Car car;

  /// The details page reuses this card as its header, where tapping it again
  /// would be a navigation loop.
  final bool interactive;

  const CarCard({super.key, required this.car, this.interactive = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Center(
                  child: Hero(
                    tag: 'car-image-${car.id}-${car.model}',
                    child: CarImage(imageUrl: car.imageUrl, height: 140),
                  ),
                ),
                if (!car.available)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _Badge(
                      label: 'Booked',
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                  ),
                if (car.rating > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _Badge(
                      label: '${car.rating.toStringAsFixed(1)} ★',
                      background: scheme.secondaryContainer,
                      foreground: scheme.onSecondaryContainer,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(car.model, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            SpecChipRow(car: car),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Flexible on both sides so a long price and the affordance
                // shrink rather than overflowing on a 320px-wide screen.
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '\$${car.pricePerDay.toStringAsFixed(0)}',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: scheme.primary),
                        ),
                        TextSpan(
                          text: ' / day',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (interactive)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'Details',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: scheme.primary),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!interactive) return card;

    return Semantics(
      button: true,
      label: '${car.model}, \$${car.pricePerDay.toStringAsFixed(0)} per day',
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CarDetailsPage(car: car)),
          );
        },
        child: card,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: foreground, fontSize: 12),
      ),
    );
  }
}
