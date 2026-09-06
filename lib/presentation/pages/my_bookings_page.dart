import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/domain/entities/price_quote.dart';
import 'package:car_rental_app/injection_container.dart';
import 'package:car_rental_app/presentation/bloc/booking/my_bookings_cubit.dart';
import 'package:car_rental_app/presentation/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MyBookingsCubit>()..load(),
      child: const MyBookingsView(),
    );
  }
}

/// Split out so tests can supply their own cubit.
class MyBookingsView extends StatelessWidget {
  const MyBookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My bookings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            return switch (state) {
              MyBookingsLoading() =>
                const Center(child: CircularProgressIndicator()),
              MyBookingsError(:final message) => StatusView(
                  icon: Icons.wifi_off_outlined,
                  title: 'Could not load your bookings',
                  body: message,
                  onRetry: () => context.read<MyBookingsCubit>().load(),
                ),
              MyBookingsLoaded(:final upcoming, :final past, :final asOf) =>
                TabBarView(
                  children: [
                    _BookingList(
                      asOf: asOf,
                      bookings: upcoming,
                      emptyTitle: 'No upcoming bookings',
                      emptyBody: 'Cars you book will appear here.',
                    ),
                    _BookingList(
                      asOf: asOf,
                      bookings: past,
                      emptyTitle: 'Nothing here yet',
                      emptyBody: 'Past and cancelled bookings appear here.',
                    ),
                  ],
                ),
            };
          },
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final DateTime asOf;
  final List<Booking> bookings;
  final String emptyTitle;
  final String emptyBody;

  const _BookingList({
    required this.asOf,
    required this.bookings,
    required this.emptyTitle,
    required this.emptyBody,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return StatusView(
        icon: Icons.event_note_outlined,
        title: emptyTitle,
        body: emptyBody,
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<MyBookingsCubit>().load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) =>
            _BookingCard(booking: bookings[index], asOf: asOf),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final DateTime asOf;

  const _BookingCard({required this.booking, required this.asOf});

  static final _dateFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.carModel,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatusChip(status: booking.statusAt(asOf)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_dateFormat.format(booking.start)} to '
              '${_dateFormat.format(booking.end)}'
              '  ·  ${booking.days} '
              '${booking.days == 1 ? 'day' : 'days'}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${booking.reference}  ·  '
              '${PriceQuote.format(booking.totalCents)}',
              style: theme.textTheme.bodyMedium,
            ),
            if (booking.isCancellableAt(asOf)) ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _confirmCancel(context),
                  child: const Text('Cancel booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<MyBookingsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(
          'Your ${booking.carModel} booking for '
          '${_dateFormat.format(booking.start)} will be released. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await cubit.cancel(booking.id);
  }
}

class _StatusChip extends StatelessWidget {
  final BookingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (background, foreground) = switch (status) {
      BookingStatus.cancelled => (
          scheme.errorContainer,
          scheme.onErrorContainer
        ),
      BookingStatus.completed => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant
        ),
      _ => (scheme.primaryContainer, scheme.onPrimaryContainer),
    };

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
        status.label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: foreground, fontSize: 12),
      ),
    );
  }
}
