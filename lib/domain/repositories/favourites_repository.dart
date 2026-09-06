abstract class FavouritesRepository {
  /// Car ids the user has saved.
  Future<Set<String>> forUser(String userId);

  /// Adds or removes a car, returning the new state for that car.
  Future<bool> toggle({required String userId, required String carId});
}
