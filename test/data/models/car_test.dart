import 'package:car_rental_app/data/models/car.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Car.fromMap', () {
    test('parses doubles', () {
      final car = Car.fromMap({
        'model': 'Tesla Model 3',
        'distance': 320.5,
        'fuelCapacity': 54.0,
        'pricePerDay': 89.99,
      });

      expect(car.model, 'Tesla Model 3');
      expect(car.distance, 320.5);
      expect(car.fuelCapacity, 54.0);
      expect(car.pricePerDay, 89.99);
    });

    test('coerces ints, which is how Firestore stores whole numbers', () {
      final car = Car.fromMap({
        'model': 'BMW M4',
        'distance': 300,
        'fuelCapacity': 60,
        'pricePerDay': 120,
      });

      expect(car.distance, 300.0);
      expect(car.fuelCapacity, 60.0);
      expect(car.pricePerDay, 120.0);
    });

    test('coerces numeric strings', () {
      final car = Car.fromMap({
        'model': 'Audi A5',
        'distance': '250',
        'fuelCapacity': '48.5',
        'pricePerDay': '99',
      });

      expect(car.distance, 250.0);
      expect(car.fuelCapacity, 48.5);
      expect(car.pricePerDay, 99.0);
    });

    test('defaults missing fields instead of throwing', () {
      final car = Car.fromMap({'model': 'Mystery car'});

      expect(car.distance, 0.0);
      expect(car.fuelCapacity, 0.0);
      expect(car.pricePerDay, 0.0);
    });

    test('defaults null fields instead of throwing', () {
      final car = Car.fromMap({
        'model': null,
        'distance': null,
        'fuelCapacity': null,
        'pricePerDay': null,
      });

      expect(car.model, 'Unknown model');
      expect(car.distance, 0.0);
    });

    test('falls back to the legacy pricePerHour field', () {
      final car = Car.fromMap({'model': 'Old doc', 'pricePerHour': 45});

      expect(car.pricePerDay, 45.0);
    });

    test('an unparseable value does not throw', () {
      final car = Car.fromMap({'model': 'Weird', 'distance': 'not a number'});

      expect(car.distance, 0.0);
    });

    test('reads the document id', () {
      final car = Car.fromMap({'model': 'BMW M4'}, id: 'abc123');

      expect(car.id, 'abc123');
    });

    test('reads a GeoPoint location', () {
      final car = Car.fromMap({
        'model': 'BMW M4',
        'location': const GeoPoint(32.49, 74.54),
      });

      expect(car.hasLocation, isTrue);
      expect(car.latitude, closeTo(32.49, 0.001));
      expect(car.longitude, closeTo(74.54, 0.001));
    });

    test('accepts flat latitude and longitude fields', () {
      final car = Car.fromMap({
        'model': 'BMW M4',
        'latitude': 32.49,
        'longitude': 74.54,
      });

      expect(car.hasLocation, isTrue);
    });

    test('a document with no location reports hasLocation false', () {
      expect(Car.fromMap({'model': 'BMW M4'}).hasLocation, isFalse);
    });

    test('parses transmission and fuel type, including aliases', () {
      expect(
        Car.fromMap({'model': 'a', 'transmission': 'AUTO'}).transmission,
        Transmission.automatic,
      );
      expect(
        Car.fromMap({'model': 'a', 'fuelType': 'EV'}).fuelType,
        FuelType.electric,
      );
      expect(
        Car.fromMap({'model': 'a', 'fuelType': 'nonsense'}).fuelType,
        FuelType.unknown,
      );
    });

    test('labels capacity in kWh for electric cars and litres otherwise', () {
      final ev = Car.fromMap({
        'model': 'a',
        'fuelType': 'electric',
        'fuelCapacity': 77,
      });
      final petrol = Car.fromMap({
        'model': 'a',
        'fuelType': 'petrol',
        'fuelCapacity': 60,
      });

      expect(ev.capacityLabel, '77 kWh');
      expect(petrol.capacityLabel, '60 L');
    });

    test('defaults available to true when the field is absent', () {
      expect(Car.fromMap({'model': 'a'}).available, isTrue);
      expect(Car.fromMap({'model': 'a', 'available': false}).available, isFalse);
    });

    test('compares by value', () {
      const a = Car(
        model: 'X',
        distance: 1,
        fuelCapacity: 2,
        pricePerDay: 3,
      );
      const b = Car(
        model: 'X',
        distance: 1,
        fuelCapacity: 2,
        pricePerDay: 3,
      );

      expect(a, equals(b));
    });

    test('toMap round-trips', () {
      const car = Car(
        model: 'Kia EV6',
        distance: 400,
        fuelCapacity: 77,
        pricePerDay: 110,
      );

      final restored = Car.fromMap(car.toMap());

      expect(restored.model, car.model);
      expect(restored.distance, car.distance);
      expect(restored.fuelCapacity, car.fuelCapacity);
      expect(restored.pricePerDay, car.pricePerDay);
    });
  });
}
