import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:equatable/equatable.dart';

/// The price breakdown a user sees before booking.
///
/// Money is held in whole cents. Doing the arithmetic in `double` dollars lets
/// rounding drift, so a total can disagree with the sum of the lines shown
/// above it.
class PriceQuote extends Equatable {
  /// Proportion of the subtotal taken as the service fee.
  static const double serviceFeeRate = 0.10;

  /// Refundable deposit held against damage, in cents.
  static const int standardDepositCents = 20000;

  /// Delivery is waived from this many days, the usual weekly-rate incentive.
  static const int freeDeliveryFromDays = 7;

  /// Delivery charge in cents when it is not waived.
  static const int standardDeliveryFeeCents = 2500;

  final int days;
  final int dailyRateCents;
  final int subtotalCents;
  final int serviceFeeCents;
  final int deliveryFeeCents;
  final int depositCents;

  const PriceQuote._({
    required this.days,
    required this.dailyRateCents,
    required this.subtotalCents,
    required this.serviceFeeCents,
    required this.deliveryFeeCents,
    required this.depositCents,
  });

  factory PriceQuote.forPeriod({
    required RentalPeriod period,
    required double pricePerDay,
  }) {
    final rate = (pricePerDay * 100).round();
    final days = period.days;
    final subtotal = rate * days;

    return PriceQuote._(
      days: days,
      dailyRateCents: rate,
      subtotalCents: subtotal,
      serviceFeeCents: (subtotal * serviceFeeRate).round(),
      deliveryFeeCents:
          days >= freeDeliveryFromDays ? 0 : standardDeliveryFeeCents,
      depositCents: standardDepositCents,
    );
  }

  /// The rental cost, excluding the refundable deposit.
  int get totalCents => subtotalCents + serviceFeeCents + deliveryFeeCents;

  /// What actually leaves the account, deposit included.
  int get chargedTodayCents => totalCents + depositCents;

  bool get deliveryWaived => deliveryFeeCents == 0;

  double get total => totalCents / 100;

  static String format(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

  @override
  List<Object?> get props => [
        days,
        dailyRateCents,
        subtotalCents,
        serviceFeeCents,
        deliveryFeeCents,
        depositCents,
      ];
}
