import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/core/router/app_router.dart';
import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/domain/entities/price_quote.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookingConfirmationPage extends StatelessWidget {
  final Booking booking;

  const BookingConfirmationPage({super.key, required this.booking});

  static final _dateFormat = DateFormat('EEE d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking confirmed')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 48,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'You have got the ${booking.carModel}',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'We have emailed the details. Show the reference below at pick-up.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _Row(
                    label: 'Reference',
                    value: booking.reference,
                    emphasise: true,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _Row(
                    label: 'Pick-up',
                    value: _dateFormat.format(booking.start),
                  ),
                  _Row(
                    label: 'Return',
                    value: _dateFormat.format(booking.end),
                  ),
                  _Row(
                    label: 'Duration',
                    value: '${booking.days} '
                        '${booking.days == 1 ? 'day' : 'days'}',
                  ),
                  const Divider(height: AppSpacing.lg),
                  _Row(
                    label: 'Rental total',
                    value: PriceQuote.format(booking.totalCents),
                  ),
                  _Row(
                    label: 'Deposit (refundable)',
                    value: PriceQuote.format(booking.depositCents),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => context.go(Routes.bookings),
            child: const Text('View my bookings'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () => context.go(Routes.cars),
            child: const Text('Back to the start'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasise;

  const _Row({
    required this.label,
    required this.value,
    this.emphasise = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: AppSpacing.sm),
          Text(
            value,
            style: emphasise
                ? theme.textTheme.headlineSmall
                    ?.copyWith(color: theme.colorScheme.primary)
                : theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
