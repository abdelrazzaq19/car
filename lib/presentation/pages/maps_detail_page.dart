import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/widgets/book_now_button.dart';
import 'package:car_rental_app/presentation/widgets/spec_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapsDetailPage extends StatelessWidget {
  final Car car;

  /// Used only when a document carries no location of its own.
  static const LatLng _fallbackCenter = LatLng(32.4935378, 74.5411575);

  const MapsDetailPage({super.key, required this.car});

  LatLng get _center => car.hasLocation
      ? LatLng(car.latitude!, car.longitude!)
      : _fallbackCenter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(car.model),
      ),
      body: Stack(
        children: [
          FlutterMap(
            // flutter_map v6 renamed `center` / `zoom`.
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.car_rental_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 44,
                    height: 44,
                    child: _Pin(available: car.available),
                  ),
                ],
              ),
            ],
          ),
          if (!car.hasLocation)
            const Positioned(
              top: kToolbarHeight + 40,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _ApproximateLocationBanner(),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CarSheet(car: car),
          ),
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final bool available;

  const _Pin({required this.available});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = available ? scheme.primary : scheme.error;

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
    );
  }
}

class _ApproximateLocationBanner extends StatelessWidget {
  const _ApproximateLocationBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'This listing has no exact location yet, so an approximate '
              'pick-up area is shown.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarSheet extends StatelessWidget {
  final Car car;

  const _CarSheet({required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(car.model, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              SpecChipRow(car: car),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text.rich(
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
                  ),
                  const Spacer(),
                  BookNowButton(car: car),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
