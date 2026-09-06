import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/car_query.dart';
import 'package:flutter_test/flutter_test.dart';

const _tesla = Car(
  id: 'a',
  model: 'Tesla Model 3',
  distance: 491,
  fuelCapacity: 60,
  pricePerDay: 89,
  seats: 5,
  transmission: Transmission.automatic,
  fuelType: FuelType.electric,
  rating: 4.8,
);

const _bmw = Car(
  id: 'b',
  model: 'BMW M4 Competition',
  distance: 520,
  fuelCapacity: 59,
  pricePerDay: 175,
  seats: 4,
  transmission: Transmission.manual,
  fuelType: FuelType.petrol,
  rating: 4.2,
);

const _corolla = Car(
  id: 'c',
  model: 'Toyota Corolla Hybrid',
  distance: 850,
  fuelCapacity: 43,
  pricePerDay: 55,
  seats: 5,
  transmission: Transmission.automatic,
  fuelType: FuelType.hybrid,
  rating: 4.7,
  available: false,
);

const _all = [_tesla, _bmw, _corolla];

List<String> models(List<Car> cars) => cars.map((c) => c.model).toList();

void main() {
  group('search', () {
    test('matches a partial model, case insensitively', () {
      expect(
        models(const CarQuery(search: 'tesla').apply(_all)),
        ['Tesla Model 3'],
      );
      expect(
        models(const CarQuery(search: 'COROLLA').apply(_all)),
        ['Toyota Corolla Hybrid'],
      );
    });

    test('ignores surrounding whitespace', () {
      expect(const CarQuery(search: '  bmw  ').apply(_all), hasLength(1));
    });

    test('an all-whitespace search is not a filter', () {
      expect(const CarQuery(search: '   ').hasFilters, isFalse);
      expect(const CarQuery(search: '   ').apply(_all), hasLength(3));
    });

    test('no match yields an empty list', () {
      expect(const CarQuery(search: 'lamborghini').apply(_all), isEmpty);
    });
  });

  group('filters', () {
    test('price bounds are inclusive', () {
      expect(const CarQuery(minPrice: 89, maxPrice: 89).apply(_all), [_tesla]);
    });

    test('a price range narrows correctly', () {
      expect(
        models(const CarQuery(minPrice: 60, maxPrice: 100).apply(_all)),
        ['Tesla Model 3'],
      );
    });

    test('seats filter accepts any of the chosen values', () {
      expect(
        const CarQuery(seats: {5}).apply(_all),
        [_tesla, _corolla],
      );
      expect(const CarQuery(seats: {4, 5}).apply(_all), hasLength(3));
    });

    test('transmission and fuel filter independently', () {
      expect(
        const CarQuery(transmissions: {Transmission.manual}).apply(_all),
        [_bmw],
      );
      expect(
        const CarQuery(fuelTypes: {FuelType.electric}).apply(_all),
        [_tesla],
      );
    });

    test('availableOnly hides booked cars', () {
      expect(
        models(const CarQuery(availableOnly: true).apply(_all)),
        ['Tesla Model 3', 'BMW M4 Competition'],
      );
    });

    test('filters combine as AND', () {
      const query = CarQuery(
        seats: {5},
        fuelTypes: {FuelType.hybrid},
        availableOnly: true,
      );

      // The only 5-seat hybrid is unavailable, so nothing matches.
      expect(query.apply(_all), isEmpty);
    });

    test('an empty query returns everything unchanged', () {
      expect(CarQuery.empty.apply(_all), _all);
      expect(CarQuery.empty.hasFilters, isFalse);
    });
  });

  group('sorting', () {
    test('price ascending and descending', () {
      expect(
        models(const CarQuery(sort: CarSort.priceLowToHigh).apply(_all)),
        ['Toyota Corolla Hybrid', 'Tesla Model 3', 'BMW M4 Competition'],
      );
      expect(
        models(const CarQuery(sort: CarSort.priceHighToLow).apply(_all)).first,
        'BMW M4 Competition',
      );
    });

    test('rating descending', () {
      expect(
        models(const CarQuery(sort: CarSort.ratingHighToLow).apply(_all)).first,
        'Tesla Model 3',
      );
    });

    test('recommended preserves the source order', () {
      expect(const CarQuery(sort: CarSort.recommended).apply(_all), _all);
    });

    test('nearest falls back to the source order without a position', () {
      expect(const CarQuery(sort: CarSort.nearest).apply(_all), _all);
    });

    test('nearest orders by the supplied distance', () {
      final distances = {'a': 10.0, 'b': 2.0, 'c': 5.0};

      final sorted = const CarQuery(sort: CarSort.nearest).apply(
        _all,
        distanceTo: (car) => distances[car.id],
      );

      expect(models(sorted), [
        'BMW M4 Competition',
        'Toyota Corolla Hybrid',
        'Tesla Model 3',
      ]);
    });

    test('cars without a location sink to the bottom', () {
      final sorted = const CarQuery(sort: CarSort.nearest).apply(
        _all,
        distanceTo: (car) => car.id == 'b' ? null : 5.0,
      );

      expect(models(sorted).last, 'BMW M4 Competition');
    });

    test('sorting and filtering apply together', () {
      const query = CarQuery(
        availableOnly: true,
        sort: CarSort.priceHighToLow,
      );

      expect(
        models(query.apply(_all)),
        ['BMW M4 Competition', 'Tesla Model 3'],
      );
    });
  });

  group('bookkeeping', () {
    test('sort alone is not a filter', () {
      expect(const CarQuery(sort: CarSort.priceLowToHigh).hasFilters, isFalse);
    });

    test('counts each active filter group once', () {
      expect(CarQuery.empty.activeFilterCount, 0);
      expect(const CarQuery(search: 'a').activeFilterCount, 1);
      // A min and a max are one price filter, not two.
      expect(const CarQuery(minPrice: 1, maxPrice: 2).activeFilterCount, 1);
      expect(
        const CarQuery(search: 'a', seats: {5}, availableOnly: true)
            .activeFilterCount,
        3,
      );
    });

    test('cleared drops the filters but keeps the sort', () {
      const query = CarQuery(
        search: 'tesla',
        seats: {5},
        sort: CarSort.priceHighToLow,
      );

      final cleared = query.cleared();

      expect(cleared.hasFilters, isFalse);
      expect(cleared.sort, CarSort.priceHighToLow);
    });

    test('copyWith clearPrice removes both bounds', () {
      const query = CarQuery(minPrice: 10, maxPrice: 20);

      final cleared = query.copyWith(clearPrice: true);

      expect(cleared.minPrice, isNull);
      expect(cleared.maxPrice, isNull);
    });

    test('only nearest needs a location', () {
      for (final sort in CarSort.values) {
        expect(sort.needsUserLocation, sort == CarSort.nearest);
      }
    });

    test('every sort has a label', () {
      for (final sort in CarSort.values) {
        expect(sort.label, isNotEmpty);
      }
    });

    test('compares by value', () {
      expect(const CarQuery(search: 'a'), const CarQuery(search: 'a'));
      expect(const CarQuery(search: 'a'), isNot(const CarQuery(search: 'b')));
    });
  });
}
