import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum Transmission {
  automatic,
  manual,
  unknown;

  static Transmission parse(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'automatic' || 'auto' => Transmission.automatic,
      'manual' => Transmission.manual,
      _ => Transmission.unknown,
    };
  }

  String get label => switch (this) {
        Transmission.automatic => 'Automatic',
        Transmission.manual => 'Manual',
        Transmission.unknown => 'Transmission n/a',
      };
}

enum FuelType {
  petrol,
  diesel,
  hybrid,
  electric,
  unknown;

  static FuelType parse(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'petrol' || 'gasoline' || 'gas' => FuelType.petrol,
      'diesel' => FuelType.diesel,
      'hybrid' => FuelType.hybrid,
      'electric' || 'ev' => FuelType.electric,
      _ => FuelType.unknown,
    };
  }

  String get label => switch (this) {
        FuelType.petrol => 'Petrol',
        FuelType.diesel => 'Diesel',
        FuelType.hybrid => 'Hybrid',
        FuelType.electric => 'Electric',
        FuelType.unknown => 'Fuel n/a',
      };

  bool get isElectric => this == FuelType.electric;
}

/// A rentable car.
///
/// Every field is parsed defensively. Firestore stores whole numbers as `int`,
/// so a document written as `distance: 300` would otherwise fail an implicit
/// cast to `double` and take the whole list load down with it. Fields added
/// after the first release all have defaults, so documents written before them
/// still parse.
class Car extends Equatable {
  final String id;
  final String model;

  /// Range on a full tank or charge, in kilometres.
  final double distance;

  /// Tank size in litres, or battery size in kWh when [fuelType] is electric.
  final double fuelCapacity;
  final double pricePerDay;

  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final int seats;
  final Transmission transmission;
  final FuelType fuelType;
  final double rating;
  final int reviewCount;
  final bool available;

  /// Who is renting the car out. Null when the document does not say, in which
  /// case the UI shows a neutral placeholder rather than inventing a person.
  final String? ownerName;
  final String? ownerPhotoUrl;
  final bool ownerVerified;

  const Car({
    this.id = '',
    required this.model,
    required this.distance,
    required this.fuelCapacity,
    required this.pricePerDay,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.seats = 0,
    this.transmission = Transmission.unknown,
    this.fuelType = FuelType.unknown,
    this.rating = 0,
    this.reviewCount = 0,
    this.available = true,
    this.ownerName,
    this.ownerPhotoUrl,
    this.ownerVerified = false,
  });

  factory Car.fromMap(Map<String, dynamic> map, {String id = ''}) {
    final location = map['location'];
    return Car(
      id: id.isNotEmpty ? id : _toStringValue(map['id'], fallback: ''),
      model: _toStringValue(map['model'], fallback: 'Unknown model'),
      distance: _toDouble(map['distance']),
      fuelCapacity: _toDouble(map['fuelCapacity']),
      // `pricePerHour` is the legacy field name; read it as a fallback so
      // documents written before the per-day switch still parse.
      pricePerDay: _toDouble(map['pricePerDay'] ?? map['pricePerHour']),
      imageUrl: _toNullableString(map['imageUrl']),
      latitude: location is GeoPoint
          ? location.latitude
          : _toNullableDouble(map['latitude']),
      longitude: location is GeoPoint
          ? location.longitude
          : _toNullableDouble(map['longitude']),
      seats: _toDouble(map['seats']).round(),
      transmission: Transmission.parse(map['transmission']),
      fuelType: FuelType.parse(map['fuelType']),
      rating: _toDouble(map['rating']),
      reviewCount: _toDouble(map['reviewCount']).round(),
      available: map['available'] is bool ? map['available'] as bool : true,
      ownerName: _toNullableString(map['ownerName']),
      ownerPhotoUrl: _toNullableString(map['ownerPhotoUrl']),
      ownerVerified:
          map['ownerVerified'] is bool ? map['ownerVerified'] as bool : false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'model': model,
      'distance': distance,
      'fuelCapacity': fuelCapacity,
      'pricePerDay': pricePerDay,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (hasLocation) 'location': GeoPoint(latitude!, longitude!),
      'seats': seats,
      'transmission': transmission.name,
      'fuelType': fuelType.name,
      'rating': rating,
      'reviewCount': reviewCount,
      'available': available,
      if (ownerName != null) 'ownerName': ownerName,
      if (ownerPhotoUrl != null) 'ownerPhotoUrl': ownerPhotoUrl,
      'ownerVerified': ownerVerified,
    };
  }

  bool get hasLocation => latitude != null && longitude != null;

  /// Litres for a combustion car, kWh for an electric one.
  String get capacityLabel => fuelType.isElectric
      ? '${_trim(fuelCapacity)} kWh'
      : '${_trim(fuelCapacity)} L';

  String get rangeLabel => '${_trim(distance)} km';

  static String _trim(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  /// Coerces `int`, `double`, numeric `String` and `null` into a `double`.
  static double _toDouble(Object? value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _toNullableDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String? _toNullableString(Object? value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static String _toStringValue(Object? value, {required String fallback}) {
    if (value is String && value.isNotEmpty) return value;
    if (value == null) return fallback;
    return value.toString();
  }

  @override
  List<Object?> get props => [
        id,
        model,
        distance,
        fuelCapacity,
        pricePerDay,
        imageUrl,
        latitude,
        longitude,
        seats,
        transmission,
        fuelType,
        rating,
        reviewCount,
        available,
        ownerName,
        ownerPhotoUrl,
        ownerVerified,
      ];
}
