import 'package:car_rental_app/domain/entities/price_quote.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 5);

  RentalPeriod periodOfDays(int days) {
    return RentalPeriod.validate(
      start: now,
      end: now.add(Duration(days: days)),
      now: now,
    ).period!;
  }

  PriceQuote quote(int days, double rate) => PriceQuote.forPeriod(
        period: periodOfDays(days),
        pricePerDay: rate,
      );

  test('a three-day rental at 50 per day has a base of 150', () {
    final q = quote(3, 50);

    expect(q.days, 3);
    expect(q.subtotalCents, 15000);
  });

  test('the service fee is ten percent of the subtotal', () {
    expect(quote(3, 50).serviceFeeCents, 1500);
  });

  test('the total is the sum of the lines shown to the user', () {
    final q = quote(3, 50);

    expect(
      q.totalCents,
      q.subtotalCents + q.serviceFeeCents + q.deliveryFeeCents,
    );
  });

  test('the deposit is charged on top but excluded from the rental total', () {
    final q = quote(3, 50);

    expect(q.depositCents, PriceQuote.standardDepositCents);
    expect(q.chargedTodayCents, q.totalCents + PriceQuote.standardDepositCents);
    expect(q.totalCents, lessThan(q.chargedTodayCents));
  });

  test('delivery is charged under a week and waived from a week', () {
    expect(quote(6, 50).deliveryFeeCents, PriceQuote.standardDeliveryFeeCents);
    expect(quote(6, 50).deliveryWaived, isFalse);

    expect(quote(7, 50).deliveryFeeCents, 0);
    expect(quote(7, 50).deliveryWaived, isTrue);
  });

  test('a fractional rate does not drift', () {
    // 89.99 a day for 3 days is 269.97 exactly, not 269.96999999999997.
    final q = quote(3, 89.99);

    expect(q.subtotalCents, 26997);
    expect(PriceQuote.format(q.subtotalCents), '\$269.97');
  });

  test('a rate with sub-cent precision rounds once, at the rate', () {
    final q = quote(3, 33.333);

    expect(q.dailyRateCents, 3333);
    expect(q.subtotalCents, 9999);
  });

  test('a zero rate produces a quote rather than throwing', () {
    final q = quote(3, 0);

    expect(q.subtotalCents, 0);
    expect(q.serviceFeeCents, 0);
    // Delivery and deposit still apply.
    expect(q.totalCents, PriceQuote.standardDeliveryFeeCents);
  });

  test('a longer rental costs more', () {
    expect(quote(5, 50).totalCents, greaterThan(quote(3, 50).totalCents));
  });

  test('format renders two decimal places', () {
    expect(PriceQuote.format(0), '\$0.00');
    expect(PriceQuote.format(5), '\$0.05');
    expect(PriceQuote.format(123456), '\$1234.56');
  });

  test('compares by value', () {
    expect(quote(3, 50), equals(quote(3, 50)));
    expect(quote(3, 50), isNot(equals(quote(4, 50))));
  });
}
