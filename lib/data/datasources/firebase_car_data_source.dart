import 'package:car_rental_app/data/models/car.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCarDataSource {
  final FirebaseFirestore firestore;

  FirebaseCarDataSource({required this.firestore});

  Future<List<Car>> getCars() async {
    final snapshot = await firestore.collection('cars').get();
    final cars = <Car>[];

    for (final doc in snapshot.docs) {
      // One malformed document must not take the whole list down.
      try {
        cars.add(Car.fromMap(doc.data(), id: doc.id));
      } catch (_) {
        continue;
      }
    }

    return cars;
  }
}
