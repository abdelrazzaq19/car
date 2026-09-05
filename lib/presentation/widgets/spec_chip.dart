import 'package:car_rental_app/core/theme/app_tokens.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:flutter/material.dart';

/// A single labelled spec, e.g. "5 seats" or "Automatic".
class SpecChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const SpecChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// The car's specs as a wrapping chip row, so it never overflows on a narrow
/// screen the way a fixed `Row` did.
class SpecChipRow extends StatelessWidget {
  final Car car;

  const SpecChipRow({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        SpecChip(icon: Icons.route_outlined, label: car.rangeLabel),
        SpecChip(
          icon: car.fuelType.isElectric
              ? Icons.electric_bolt_outlined
              : Icons.local_gas_station_outlined,
          label: car.capacityLabel,
        ),
        if (car.seats > 0)
          SpecChip(
            icon: Icons.event_seat_outlined,
            label: '${car.seats} seats',
          ),
        if (car.transmission != Transmission.unknown)
          SpecChip(
            icon: Icons.settings_outlined,
            label: car.transmission.label,
          ),
      ],
    );
  }
}
