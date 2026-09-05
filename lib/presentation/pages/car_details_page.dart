import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:car_rental_app/presentation/pages/maps_detail_page.dart';
import 'package:car_rental_app/presentation/pages/my_bookings_page.dart';
import 'package:car_rental_app/presentation/widgets/book_now_button.dart';
import 'package:car_rental_app/presentation/widgets/car_card.dart';
import 'package:car_rental_app/presentation/widgets/more_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CarDetailsPage extends StatelessWidget {
  final Car car;

  const CarDetailsPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            tooltip: 'My bookings',
            icon: const Icon(Icons.event_note_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          CarCard(car: car, interactive: false),
          const SizedBox(height: AppSpacing.lg),
          Text('Pick-up location', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _MapPreview(car: car),
          const SizedBox(height: AppSpacing.lg),
          Text('Owner', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const _OwnerTile(),
          const SizedBox(height: AppSpacing.lg),
          _SimilarCars(current: car),
        ],
      ),
      bottomNavigationBar: _BookingBar(car: car),
    );
  }
}

/// Static map thumbnail that opens the full map. The zoom animation the
/// previous version ran on a listener has been dropped: it rebuilt the entire
/// page on every frame for three seconds and served no informational purpose.
class _MapPreview extends StatelessWidget {
  final Car car;

  const _MapPreview({required this.car});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Open the map showing where this car is parked',
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MapsDetailPage(car: car)),
          );
        },
        child: ClipRRect(
          borderRadius: AppRadius.lgAll,
          child: Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Image.asset('assets/maps.png', fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                bottom: AppSpacing.md,
                right: AppSpacing.md,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: Text(
                        car.hasLocation
                            ? 'Tap to view on the map'
                            : 'Exact location shared after booking',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: scheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerTile extends StatelessWidget {
  const _OwnerTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: const CircleAvatar(
          radius: 26,
          backgroundImage: AssetImage('assets/user.png'),
        ),
        title: Text('naumanbutt2002', style: theme.textTheme.titleMedium),
        subtitle: Text(
          'Verified host · Responds within an hour',
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Icon(
          Icons.verified_outlined,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Real similar cars pulled from the loaded list, replacing the fabricated
/// entries the previous version generated by adding 100 to every number.
class _SimilarCars extends StatelessWidget {
  final Car current;

  const _SimilarCars({required this.current});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarBloc, CarState>(
      builder: (context, state) {
        if (state is! CarsLoaded) return const SizedBox.shrink();

        final similar = state.cars.where((c) => c != current).toList()
          ..sort((a, b) {
            final byPrice = (a.pricePerDay - current.pricePerDay)
                .abs()
                .compareTo((b.pricePerDay - current.pricePerDay).abs());
            return byPrice;
          });

        if (similar.isEmpty) return const SizedBox.shrink();

        final shown = similar.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Similar cars',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final car in shown) ...[
              MoreCard(car: car),
              if (car != shown.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _BookingBar extends StatelessWidget {
  final Car car;

  const _BookingBar({required this.car});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total per day', style: theme.textTheme.bodyMedium),
                Text(
                  '\$${car.pricePerDay.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: BookNowButton(car: car)),
          ],
        ),
      ),
    );
  }
}
