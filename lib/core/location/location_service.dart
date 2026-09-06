import 'package:geolocator/geolocator.dart';

/// Why a position could not be read. The caller decides the wording, and the
/// UI can distinguish "ask again" from "send them to settings".
enum LocationFailure {
  serviceDisabled,
  denied,
  deniedForever,
  failed;

  String get message => switch (this) {
        LocationFailure.serviceDisabled =>
          'Location services are turned off on this device.',
        LocationFailure.denied =>
          'Location permission is needed to sort by distance.',
        LocationFailure.deniedForever =>
          'Location permission is blocked. Enable it in Settings to sort by '
              'distance.',
        LocationFailure.failed => 'Could not read your location.',
      };

  /// Only a fresh denial is worth asking about again; a permanent block needs
  /// the system settings screen.
  bool get canRetry => this != LocationFailure.deniedForever;
}

class UserPosition {
  final double latitude;
  final double longitude;

  const UserPosition(this.latitude, this.longitude);
}

/// Wraps geolocator so the rest of the app never imports it directly, and so
/// tests can supply a fake without a platform channel.
abstract class LocationService {
  Future<({UserPosition? position, LocationFailure? failure})> current();

  /// Straight-line kilometres. Good enough for ordering a list; it is not a
  /// driving distance and is not presented as one.
  double distanceKm({
    required UserPosition from,
    required double latitude,
    required double longitude,
  });
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<({UserPosition? position, LocationFailure? failure})> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (position: null, failure: LocationFailure.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return (position: null, failure: LocationFailure.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return (position: null, failure: LocationFailure.denied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return (
        position: UserPosition(position.latitude, position.longitude),
        failure: null,
      );
    } catch (_) {
      // A timeout or a platform error must degrade, never crash the list.
      return (position: null, failure: LocationFailure.failed);
    }
  }

  @override
  double distanceKm({
    required UserPosition from,
    required double latitude,
    required double longitude,
  }) {
    final metres = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      latitude,
      longitude,
    );

    return metres / 1000;
  }
}
