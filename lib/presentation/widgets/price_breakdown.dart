import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/domain/entities/price_quote.dart';
import 'package:flutter/material.dart';

/// The itemised price. Every line is shown, so the total is never a number the
/// user has to take on trust.
class PriceBreakdown extends StatelessWidget {
  final PriceQuote quote;

  const PriceBreakdown({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _Line(
          label: '${PriceQuote.format(quote.dailyRateCents)} '
              '× ${quote.days} ${quote.days == 1 ? 'day' : 'days'}',
          value: PriceQuote.format(quote.subtotalCents),
        ),
        _Line(
          label: 'Service fee',
          value: PriceQuote.format(quote.serviceFeeCents),
        ),
        _Line(
          label:
              quote.deliveryWaived ? 'Delivery (free over a week)' : 'Delivery',
          value: quote.deliveryWaived
              ? 'Free'
              : PriceQuote.format(quote.deliveryFeeCents),
          muted: quote.deliveryWaived,
        ),
        const Divider(height: AppSpacing.lg),
        _Line(
          label: 'Total',
          value: PriceQuote.format(quote.totalCents),
          emphasise: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        _Line(
          label: 'Refundable deposit',
          value: PriceQuote.format(quote.depositCents),
          muted: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                'Charged today, deposit included: '
                '${PriceQuote.format(quote.chargedTodayCents)}. '
                'The deposit is returned after the car is checked back in.',
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasise;
  final bool muted;

  const _Line({
    required this.label,
    required this.value,
    this.emphasise = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasise
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyMedium?.copyWith(
            color: muted
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: AppSpacing.sm),
          Text(value, style: style),
        ],
      ),
    );
  }
}
