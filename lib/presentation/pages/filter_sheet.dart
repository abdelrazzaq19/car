import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/car_query.dart';
import 'package:flutter/material.dart';

/// Filter and sort controls.
///
/// Edits a local copy and returns it on "Apply", so backing out of the sheet
/// leaves the list untouched.
class FilterSheet extends StatefulWidget {
  final CarQuery query;
  final double maxPriceAvailable;

  const FilterSheet({
    super.key,
    required this.query,
    required this.maxPriceAvailable,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late CarQuery _draft = widget.query;
  late RangeValues _price = RangeValues(
    widget.query.minPrice ?? 0,
    widget.query.maxPrice ?? _ceiling,
  );

  /// Rounded up so the slider's top end is a sensible number and always at
  /// least covers the most expensive car.
  double get _ceiling {
    final max = widget.maxPriceAvailable;
    if (max <= 0) return 500;
    return (max / 50).ceil() * 50;
  }

  bool get _priceTouched => _price.start > 0 || _price.end < _ceiling;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filter', style: theme.textTheme.headlineSmall),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _draft = _draft.cleared();
                    _price = RangeValues(0, _ceiling);
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Sort by'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final sort in CarSort.values)
                          ChoiceChip(
                            label: Text(sort.label),
                            selected: _draft.sort == sort,
                            onSelected: (_) => setState(
                                () => _draft = _draft.copyWith(sort: sort)),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Label(
                      'Price per day: '
                      '\$${_price.start.round()} – \$${_price.end.round()}',
                    ),
                    RangeSlider(
                      values: _price,
                      min: 0,
                      max: _ceiling,
                      divisions: (_ceiling / 10).round().clamp(1, 100),
                      labels: RangeLabels(
                        '\$${_price.start.round()}',
                        '\$${_price.end.round()}',
                      ),
                      onChanged: (value) => setState(() => _price = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _Label('Seats'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final seats in const [2, 4, 5, 7])
                          FilterChip(
                            label: Text('$seats'),
                            selected: _draft.seats.contains(seats),
                            onSelected: (selected) => setState(() {
                              final next = Set<int>.from(_draft.seats);
                              selected ? next.add(seats) : next.remove(seats);
                              _draft = _draft.copyWith(seats: next);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Label('Transmission'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final value in const [
                          Transmission.automatic,
                          Transmission.manual,
                        ])
                          FilterChip(
                            label: Text(value.label),
                            selected: _draft.transmissions.contains(value),
                            onSelected: (selected) => setState(() {
                              final next =
                                  Set<Transmission>.from(_draft.transmissions);
                              selected ? next.add(value) : next.remove(value);
                              _draft = _draft.copyWith(transmissions: next);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _Label('Fuel'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final value in const [
                          FuelType.petrol,
                          FuelType.diesel,
                          FuelType.hybrid,
                          FuelType.electric,
                        ])
                          FilterChip(
                            label: Text(value.label),
                            selected: _draft.fuelTypes.contains(value),
                            onSelected: (selected) => setState(() {
                              final next = Set<FuelType>.from(_draft.fuelTypes);
                              selected ? next.add(value) : next.remove(value);
                              _draft = _draft.copyWith(fuelTypes: next);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available only'),
                      value: _draft.availableOnly,
                      onChanged: (value) => setState(
                        () => _draft = _draft.copyWith(availableOnly: value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _result()),
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CarQuery _result() {
    // Start from a cleared price so passing null actually clears it: copyWith
    // falls back to the existing value when given null.
    final base = _draft.copyWith(clearPrice: true);

    if (!_priceTouched) return base;

    return base.copyWith(
      minPrice: _price.start == 0 ? null : _price.start,
      maxPrice: _price.end >= _ceiling ? null : _price.end,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
