import 'package:car_rental_app/core/router/app_router.dart';
import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/core/theme/theme_cubit.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/car_query.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:car_rental_app/presentation/pages/filter_sheet.dart';
import 'package:car_rental_app/presentation/widgets/car_card.dart';
import 'package:car_rental_app/presentation/widgets/car_card_skeleton.dart';
import 'package:car_rental_app/presentation/widgets/car_search_bar.dart';
import 'package:car_rental_app/presentation/widgets/connectivity_banner.dart';
import 'package:car_rental_app/presentation/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CarListScreen extends StatelessWidget {
  const CarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Choose your car'),
          actions: [
            IconButton(
              tooltip: 'My bookings',
              icon: const Icon(Icons.event_note_outlined),
              onPressed: () => context.push(Routes.bookings),
            ),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, mode) {
                final cubit = context.read<ThemeCubit>();
                return IconButton(
                  onPressed: cubit.toggle,
                  icon: Icon(cubit.icon),
                  tooltip: cubit.label,
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All cars'),
              Tab(text: 'Saved'),
            ],
          ),
        ),
        body: Column(
          children: [
            const ConnectivityBanner(),
            Expanded(
              child: BlocBuilder<CarBloc, CarState>(
                builder: (context, state) {
                  return switch (state) {
                    CarsLoading() => const _SkeletonList(),
                    CarsError(:final message) => StatusView(
                        icon: Icons.wifi_off_outlined,
                        title: 'Could not load cars',
                        body: message,
                        onRetry: () => context.read<CarBloc>().add(LoadCars()),
                      ),
                    CarsLoaded() => TabBarView(
                        children: [
                          _AllCarsTab(state: state),
                          _SavedTab(state: state),
                        ],
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllCarsTab extends StatelessWidget {
  final CarsLoaded state;

  const _AllCarsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CarBloc>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: CarSearchBar(
                  initialValue: state.query.search,
                  onChanged: (value) => bloc
                      .add(QueryChanged(state.query.copyWith(search: value))),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterButton(state: state),
            ],
          ),
        ),
        if (state.locationFailure != null)
          _LocationNotice(state: state),
        Expanded(
          child: state.cars.isEmpty
              ? StatusView(
                  icon: state.filteredToNothing
                      ? Icons.search_off_outlined
                      : Icons.directions_car_outlined,
                  title: state.filteredToNothing
                      ? 'No cars match those filters'
                      : 'No cars available',
                  body: state.filteredToNothing
                      ? 'Try widening the price range or clearing a filter.'
                      : 'Nothing is listed for rent right now. '
                          'Pull down to refresh.',
                  actionLabel: state.filteredToNothing ? 'Clear filters' : null,
                  onRetry: state.filteredToNothing
                      ? () => bloc.add(ClearFilters())
                      : () => bloc.add(LoadCars()),
                )
              : _CarList(state: state),
        ),
      ],
    );
  }
}

class _SavedTab extends StatelessWidget {
  final CarsLoaded state;

  const _SavedTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final saved = state.favouriteCars;

    if (saved.isEmpty) {
      return const StatusView(
        icon: Icons.favorite_border,
        title: 'Nothing saved yet',
        body: 'Tap the heart on a car to keep it here for later.',
      );
    }

    return _CarList(state: state, cars: saved);
  }
}

class _CarList extends StatelessWidget {
  final CarsLoaded state;
  final List<Car>? cars;

  const _CarList({required this.state, this.cars});

  @override
  Widget build(BuildContext context) {
    final shown = cars ?? state.cars;

    return RefreshIndicator(
      onRefresh: () async => context.read<CarBloc>().add(LoadCars()),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        itemCount: shown.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final car = shown[index];
          return CarCard(
            car: car,
            isFavourite: state.isFavourite(car.id),
          );
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final CarsLoaded state;

  const _FilterButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = state.query.activeFilterCount;

    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: IconButton.filledTonal(
        tooltip: count > 0 ? '$count filters active' : 'Filter and sort',
        constraints: const BoxConstraints(
          minWidth: kMinTapTarget,
          minHeight: kMinTapTarget,
        ),
        icon: Icon(Icons.tune, color: scheme.onSecondaryContainer),
        onPressed: () => _open(context),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final bloc = context.read<CarBloc>();

    final maxPrice = state.all.fold<double>(
      0,
      (highest, car) => car.pricePerDay > highest ? car.pricePerDay : highest,
    );

    final result = await showModalBottomSheet<CarQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FilterSheet(
        query: state.query,
        maxPriceAvailable: maxPrice,
      ),
    );

    if (result == null) return;

    bloc.add(QueryChanged(result));

    // Distance ordering needs a position; ask only when it is actually chosen.
    if (result.sort.needsUserLocation) bloc.add(RequestLocation());
  }
}

/// Explains why nearest-first is not ordering anything.
class _LocationNotice extends StatelessWidget {
  final CarsLoaded state;

  const _LocationNotice({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final failure = state.locationFailure!;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              failure.message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
          if (failure.canRetry)
            TextButton(
              onPressed: () => context.read<CarBloc>().add(RequestLocation()),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => const CarCardSkeleton(),
    );
  }
}
