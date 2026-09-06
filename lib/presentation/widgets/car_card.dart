import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/core/router/app_router.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/widgets/car_image.dart';
import 'package:car_rental_app/presentation/widgets/spec_chip.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CarCard extends StatelessWidget {
  final Car car;

  /// The details page reuses this card as its header, where tapping it again
  /// would be a navigation loop.
  final bool interactive;

  /// Null when the card is shown outside a [CarBloc], e.g. in a test harness.
  final bool? isFavourite;

  const CarCard({
    super.key,
    required this.car,
    this.interactive = true,
    this.isFavourite,
  });

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
                    right: isFavourite == null ? 0 : kMinTapTarget,
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

    final tappable = interactive
        ? Semantics(
            button: true,
            label:
                '${car.model}, \$${car.pricePerDay.toStringAsFixed(0)} per day',
            child: InkWell(
              borderRadius: AppRadius.lgAll,
              onTap: () => context.push(Routes.carDetailsFor(car.id)),
              child: card,
            ),
          )
        : card;

    if (isFavourite == null) return tappable;

    // The heart is a sibling of the tappable card, not a descendant: nested
    // inside, its own semantics were swallowed by the card's label and a
    // screen reader could not reach it separately.
    return Stack(
      children: [
        tappable,
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: _FavouriteButton(
            carId: car.id,
            isFavourite: isFavourite!,
          ),
        ),
      ],
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


class _FavouriteButton extends StatelessWidget {
  final String carId;
  final bool isFavourite;

  const _FavouriteButton({
    required this.carId,
    required this.isFavourite,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      // 48dp minimum, so the heart is reachable without hitting the card.
      constraints: const BoxConstraints(
        minWidth: kMinTapTarget,
        minHeight: kMinTapTarget,
      ),
      tooltip: isFavourite ? 'Remove from saved' : 'Save this car',
      onPressed: () => context.read<CarBloc>().add(ToggleFavourite(carId)),
      icon: Icon(
        isFavourite ? Icons.favorite : Icons.favorite_border,
        color: isFavourite ? scheme.error : scheme.onSurfaceVariant,
      ),
    );
  }
}
