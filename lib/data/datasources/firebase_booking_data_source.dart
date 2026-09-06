import 'package:car_rental_app/data/models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseBookingDataSource {
  final FirebaseFirestore firestore;

  FirebaseBookingDataSource({required this.firestore});

  CollectionReference<Map<String, dynamic>> get _bookings =>
      firestore.collection('bookings');

  /// Bookings for one car that could still block new dates.
  ///
  /// Firestore allows a range filter on only one field, so this narrows on
  /// `end` and the caller checks the `start` side in memory.
  Future<List<Booking>> blockingForCar({
    required String carId,
    required DateTime from,
  }) async {
    final snapshot = await _bookings
        .where('carId', isEqualTo: carId)
        .where('end', isGreaterThan: Timestamp.fromDate(from))
        .get();

    // Date-aware: a booking whose dates have passed no longer holds them, even
    // though nothing ever wrote `completed` to it.
    final now = DateTime.now();

    return _parse(snapshot)
        .where((booking) => booking.blocksAvailabilityAt(now))
        .toList();
  }

  Future<Booking> create(Booking booking) async {
    final reference = await _bookings.add(booking.toMap());

    // Re-read so the returned booking carries the generated id, which the
    // reference code is derived from.
    return Booking.fromMap(booking.toMap(), id: reference.id);
  }

  Future<List<Booking>> forUser(String userId) async {
    final snapshot = await _bookings.where('userId', isEqualTo: userId).get();

    final bookings = _parse(snapshot);
    // Sorted client-side so the query needs no composite index.
    bookings.sort((a, b) => b.start.compareTo(a.start));
    return bookings;
  }

  Future<void> cancel(String bookingId) {
    return _bookings.doc(bookingId).update({
      'status': BookingStatus.cancelled.name,
    });
  }

  List<Booking> _parse(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final bookings = <Booking>[];

    for (final doc in snapshot.docs) {
      try {
        bookings.add(Booking.fromMap(doc.data(), id: doc.id));
      } catch (_) {
        continue;
      }
    }

    return bookings;
  }
}
