import 'package:car_rental_app/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth auth;

  AuthRepositoryImpl(this.auth);

  @override
  String? get currentUserId => auth.currentUser?.uid;

  @override
  Future<String> ensureSignedIn() async {
    final existing = auth.currentUser;
    if (existing != null) return existing.uid;

    final credential = await auth.signInAnonymously();
    final user = credential.user;

    if (user == null) {
      throw StateError('Anonymous sign-in returned no user.');
    }

    return user.uid;
  }

  @override
  Stream<String?> get userIdChanges =>
      auth.authStateChanges().map((user) => user?.uid);
}
