import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:car_rental_app/presentation/widgets/book_now_button.dart';
import 'package:car_rental_app/presentation/widgets/spec_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsDetailPage extends StatelessWidget {
  final Car car;

  /// Used only when a document carries no location of its own.
  static const LatLng fallbackCenter = LatLng(32.4935378, 74.5411575);

  const MapsDetailPage({super.key, required this.car});

  LatLng get _center => car.hasLocation
      ? LatLng(car.latitude!, car.longitude!)
      : fallbackCenter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(car.model),
        actions: [
          IconButton(
            tooltip: 'Show my location',
            icon: const Icon(Icons.my_location),
            onPressed: () => context.read<CarBloc>().add(RequestLocation()),
          ),
        ],
      ),
      body: BlocBuilder<CarBloc, CarState>(
        builder: (context, state) {
          final loaded = state is CarsLoaded ? state : null;
          final position = loaded?.position;

          // Every other car with a location, so the map shows what is nearby
          // rather than a single decorative pin.
          final others = (loaded?.all ?? const <Car>[])
              .where((other) => other != car && other.hasLocation)
              .toList();

          return Stack(
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
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.car_rental_app',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final other in others)
                        Marker(
                          point: LatLng(other.latitude!, other.longitude!),
                          width: 36,
                          height: 36,
                          child: _Pin(available: other.available, faded: true),
                        ),
                      if (position != null)
                        Marker(
                          point: LatLng(position.latitude, position.longitude),
                          width: 24,
                          height: 24,
                          child: const _UserDot(),
                        ),
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
                child: _CarSheet(car: car, center: _center),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location',
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final bool available;
  final bool faded;

  const _Pin({required this.available, this.faded = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = available ? scheme.primary : scheme.error;

    return Opacity(
      opacity: faded ? 0.55 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 1),
          ],
        ),
        child: Icon(
          Icons.directions_car,
          color: Colors.white,
          size: faded ? 16 : 20,
        ),
      ),
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
  final LatLng center;

  const _CarSheet({required this.car, required this.center});

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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      car.model,
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (car.hasLocation)
                    IconButton(
                      tooltip: 'Open in maps',
                      icon: const Icon(Icons.directions_outlined),
                      onPressed: () => _openInMaps(context),
                    ),
                ],
              ),
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

  /// Hands off to whatever maps app the platform has. A geo: URI is the
  /// portable form; the web fallback covers desktop and browsers.
  Future<void> _openInMaps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final label = Uri.encodeComponent(car.model);
    final coordinates = '${center.latitude},${center.longitude}';

    for (final uri in [
      Uri.parse('geo:$coordinates?q=$coordinates($label)'),
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$coordinates',
      ),
    ]) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        continue;
      }
    }

    messenger.showSnackBar(
      const SnackBar(content: Text('No maps app is available on this device.')),
    );
  }
}
