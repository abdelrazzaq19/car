abstract class AuthRepository {
  /// The signed-in user's id, or null when nobody is signed in.
  String? get currentUserId;

  /// Signs in anonymously if needed and returns the user id.
  ///
  /// Anonymous is enough to own a booking, and it keeps sign-up out of the
  /// booking flow. The account can be upgraded to email later without the
  /// bookings changing hands, because the uid is preserved on linking.
  Future<String> ensureSignedIn();

  Stream<String?> get userIdChanges;
}
