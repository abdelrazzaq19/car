import 'package:car_rental_app/domain/repositories/favourites_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Stored as `users/{uid}/favourites/{carId}`.
///
/// A subcollection keyed by car id makes the toggle a single document write and
/// keeps one user's saves unreadable by another under the suggested rules.
class FavouritesRepositoryImpl implements FavouritesRepository {
  final FirebaseFirestore firestore;

  FavouritesRepositoryImpl(this.firestore);

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      firestore.collection('users').doc(userId).collection('favourites');

  @override
  Future<Set<String>> forUser(String userId) async {
    final snapshot = await _collection(userId).get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  @override
  Future<bool> toggle({
    required String userId,
    required String carId,
  }) async {
    final document = _collection(userId).doc(carId);

    if ((await document.get()).exists) {
      await document.delete();
      return false;
    }

    await document.set({'savedAt': FieldValue.serverTimestamp()});
    return true;
  }
}
