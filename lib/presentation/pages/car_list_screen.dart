import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/core/theme/theme_cubit.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:car_rental_app/presentation/pages/my_bookings_page.dart';
import 'package:car_rental_app/presentation/widgets/car_card.dart';
import 'package:car_rental_app/presentation/widgets/car_card_skeleton.dart';
import 'package:car_rental_app/presentation/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CarListScreen extends StatelessWidget {
  const CarListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose your car'),
        actions: [
          IconButton(
            tooltip: 'My bookings',
            icon: const Icon(Icons.event_note_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyBookingsPage()),
            ),
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
      ),
      body: BlocBuilder<CarBloc, CarState>(
        builder: (context, state) {
          return switch (state) {
            CarsLoading() => const _SkeletonList(),
            CarsLoaded(:final cars) when cars.isEmpty => StatusView(
                icon: Icons.directions_car_outlined,
                title: 'No cars available',
                body: 'Nothing is listed for rent right now. '
                    'Check back soon, or refresh to try again.',
                onRetry: () => context.read<CarBloc>().add(LoadCars()),
              ),
            CarsLoaded(:final cars) => RefreshIndicator(
                onRefresh: () async => context.read<CarBloc>().add(LoadCars()),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xxl,
                  ),
                  itemCount: cars.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => CarCard(car: cars[index]),
                ),
              ),
            CarsError(:final message) => StatusView(
                icon: Icons.wifi_off_outlined,
                title: 'Could not load cars',
                body: message,
                onRetry: () => context.read<CarBloc>().add(LoadCars()),
              ),
          };
        },
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
