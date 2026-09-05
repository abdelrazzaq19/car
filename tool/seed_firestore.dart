// Seeds the `cars` collection with sample listings.
//
// Run against a project you are happy to write to:
//
//   flutter run -t tool/seed_firestore.dart -d chrome
//
// Existing documents with the same id are overwritten; documents not listed
// here are left alone.
import 'package:car_rental_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const _cars = <String, Map<String, dynamic>>{
  'tesla-model-3': {
    'model': 'Tesla Model 3',
    'distance': 491,
    'fuelCapacity': 60,
    'pricePerDay': 89,
    'imageUrl': null,
    'latitude': 32.4935378,
    'longitude': 74.5411575,
    'seats': 5,
    'transmission': 'automatic',
    'fuelType': 'electric',
    'rating': 4.8,
    'reviewCount': 126,
    'available': true,
  },
  'bmw-m4-competition': {
    'model': 'BMW M4 Competition',
    'distance': 520,
    'fuelCapacity': 59,
    'pricePerDay': 175,
    'imageUrl': null,
    'latitude': 32.5021,
    'longitude': 74.5288,
    'seats': 4,
    'transmission': 'automatic',
    'fuelType': 'petrol',
    'rating': 4.6,
    'reviewCount': 83,
    'available': true,
  },
  'audi-a5-sportback': {
    'model': 'Audi A5 Sportback',
    'distance': 610,
    'fuelCapacity': 58,
    'pricePerDay': 120,
    'imageUrl': null,
    'latitude': 32.4871,
    'longitude': 74.5502,
    'seats': 5,
    'transmission': 'automatic',
    'fuelType': 'diesel',
    'rating': 4.4,
    'reviewCount': 51,
    'available': true,
  },
  'toyota-corolla-hybrid': {
    'model': 'Toyota Corolla Hybrid',
    'distance': 850,
    'fuelCapacity': 43,
    'pricePerDay': 55,
    'imageUrl': null,
    'latitude': 32.4788,
    'longitude': 74.5330,
    'seats': 5,
    'transmission': 'automatic',
    'fuelType': 'hybrid',
    'rating': 4.7,
    'reviewCount': 204,
    'available': true,
  },
  'ford-ranger-wildtrak': {
    'model': 'Ford Ranger Wildtrak',
    'distance': 700,
    'fuelCapacity': 80,
    'pricePerDay': 140,
    'imageUrl': null,
    'latitude': 32.5104,
    'longitude': 74.5617,
    'seats': 5,
    'transmission': 'manual',
    'fuelType': 'diesel',
    'rating': 4.3,
    'reviewCount': 37,
    // Demonstrates the "Booked" badge and the disabled booking button.
    'available': false,
  },
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  _cars.forEach((id, data) {
    final payload = Map<String, dynamic>.from(data)..remove('imageUrl');

    if (data['imageUrl'] != null) payload['imageUrl'] = data['imageUrl'];

    payload['location'] = GeoPoint(
      (data['latitude'] as num).toDouble(),
      (data['longitude'] as num).toDouble(),
    );
    payload
      ..remove('latitude')
      ..remove('longitude');

    batch.set(firestore.collection('cars').doc(id), payload);
  });

  await batch.commit();

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Seeded ${_cars.length} cars.')),
      ),
    ),
  );
}
