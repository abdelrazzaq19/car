import 'package:car_rental_app/core/router/app_router.dart';
import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:car_rental_app/presentation/bloc/booking/booking_cubit.dart';
import 'package:car_rental_app/presentation/widgets/price_breakdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Date selection and price, shown as a bottom sheet over the car.
class BookingSheet extends StatelessWidget {
  final Car car;

  const BookingSheet({super.key, required this.car});

  static final _dateFormat = DateFormat('EEE d MMM');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<BookingCubit, BookingState>(
      listener: (context, state) {
        if (state is! BookingConfirmed) return;

        // The router has to be captured before the sheet closes: popping
        // deactivates this context, and reading it afterwards would throw.
        final router = GoRouter.of(context);

        Navigator.pop(context);
        router.push(Routes.bookingConfirmed, extra: state.booking);
      },
      builder: (context, state) {
        final cubit = context.read<BookingCubit>();

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Book ${car.model}', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.lg),
              _DateField(
                state: state,
                onPick: () => _pickDates(context, cubit, state),
              ),
              if (state is BookingInvalid) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.message,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              if (state is BookingFailed) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.message,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
              if (state is BookingQuoted) ...[
                const SizedBox(height: AppSpacing.lg),
                PriceBreakdown(quote: state.quote),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: switch (state) {
                    BookingQuoted() => cubit.confirm,
                    BookingSubmitting() => null,
                    _ => () => _pickDates(context, cubit, state),
                  },
                  child: switch (state) {
                    BookingSubmitting() => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    BookingQuoted() => const Text('Confirm booking'),
                    _ => const Text('Choose dates'),
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDates(
    BuildContext context,
    BookingCubit cubit,
    BookingState state,
  ) async {
    final today = RentalPeriod.dateOnly(DateTime.now());

    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: RentalPeriod.maxDays)),
      initialDateRange: state is BookingQuoted
          ? DateTimeRange(start: state.period.start, end: state.period.end)
          : null,
      helpText: 'Pick-up and return',
    );

    if (range == null) return;

    cubit.selectDates(start: range.start, end: range.end);
  }
}

class _DateField extends StatelessWidget {
  final BookingState state;
  final VoidCallback onPick;

  const _DateField({required this.state, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final period =
        state is BookingQuoted ? (state as BookingQuoted).period : null;

    return InkWell(
      borderRadius: AppRadius.mdAll,
      onTap: onPick,
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                period == null
                    ? 'Select your dates'
                    : '${BookingSheet._dateFormat.format(period.start)}'
                        '  →  '
                        '${BookingSheet._dateFormat.format(period.end)}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (period != null)
              Text(
                '${period.days} ${period.days == 1 ? 'day' : 'days'}',
                style: theme.textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}
