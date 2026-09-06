import 'package:car_rental_app/data/models/car.dart';
import 'package:equatable/equatable.dart';

enum CarSort {
  recommended,
  priceLowToHigh,
  priceHighToLow,
  ratingHighToLow,
  nearest;

  String get label => switch (this) {
        CarSort.recommended => 'Recommended',
        CarSort.priceLowToHigh => 'Price: low to high',
        CarSort.priceHighToLow => 'Price: high to low',
        CarSort.ratingHighToLow => 'Top rated',
        CarSort.nearest => 'Nearest to me',
      };

  /// Sorting by distance is meaningless without the user's position.
  bool get needsUserLocation => this == CarSort.nearest;
}

/// The filters and ordering applied to the car list.
///
/// Filtering lives here rather than in the bloc so it can be unit tested
/// without a widget tree, and so the list screen and any future map list stay
/// in agreement about what "matching" means.
class CarQuery extends Equatable {
  final String search;
  final double? minPrice;
  final double? maxPrice;
  final Set<int> seats;
  final Set<Transmission> transmissions;
  final Set<FuelType> fuelTypes;
  final bool availableOnly;
  final CarSort sort;

  const CarQuery({
    this.search = '',
    this.minPrice,
    this.maxPrice,
    this.seats = const {},
    this.transmissions = const {},
    this.fuelTypes = const {},
    this.availableOnly = false,
    this.sort = CarSort.recommended,
  });

  static const empty = CarQuery();

  /// True when anything narrows the list. Sorting alone does not count, so the
  /// "clear filters" affordance does not appear for a plain re-ordering.
  bool get hasFilters =>
      search.trim().isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      seats.isNotEmpty ||
      transmissions.isNotEmpty ||
      fuelTypes.isNotEmpty ||
      availableOnly;

  int get activeFilterCount => [
        search.trim().isNotEmpty,
        minPrice != null || maxPrice != null,
        seats.isNotEmpty,
        transmissions.isNotEmpty,
        fuelTypes.isNotEmpty,
        availableOnly,
      ].where((active) => active).length;

  CarQuery copyWith({
    String? search,
    double? minPrice,
    double? maxPrice,
    Set<int>? seats,
    Set<Transmission>? transmissions,
    Set<FuelType>? fuelTypes,
    bool? availableOnly,
    CarSort? sort,
    bool clearPrice = false,
  }) {
    return CarQuery(
      search: search ?? this.search,
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      seats: seats ?? this.seats,
      transmissions: transmissions ?? this.transmissions,
      fuelTypes: fuelTypes ?? this.fuelTypes,
      availableOnly: availableOnly ?? this.availableOnly,
      sort: sort ?? this.sort,
    );
  }

  /// Clears the filters but keeps the chosen ordering, which is what a user
  /// means by "clear filters".
  CarQuery cleared() => CarQuery(sort: sort);

  bool matches(Car car) {
    final term = search.trim().toLowerCase();
    if (term.isNotEmpty && !car.model.toLowerCase().contains(term)) {
      return false;
    }
    if (minPrice != null && car.pricePerDay < minPrice!) return false;
    if (maxPrice != null && car.pricePerDay > maxPrice!) return false;
    if (seats.isNotEmpty && !seats.contains(car.seats)) return false;
    if (transmissions.isNotEmpty && !transmissions.contains(car.transmission)) {
      return false;
    }
    if (fuelTypes.isNotEmpty && !fuelTypes.contains(car.fuelType)) return false;
    if (availableOnly && !car.available) return false;

    return true;
  }

  /// Applies the filters and the ordering.
  ///
  /// [distanceTo] supplies kilometres from the user, and is null when the
  /// position is unknown; nearest-first then degrades to the default order
  /// rather than producing an arbitrary one.
  List<Car> apply(
    List<Car> cars, {
    double? Function(Car car)? distanceTo,
  }) {
    final result = cars.where(matches).toList();

    switch (sort) {
      case CarSort.recommended:
        break;
      case CarSort.priceLowToHigh:
        result.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
      case CarSort.priceHighToLow:
        result.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
      case CarSort.ratingHighToLow:
        result.sort((a, b) => b.rating.compareTo(a.rating));
      case CarSort.nearest:
        if (distanceTo == null) break;
        result.sort((a, b) {
          final da = distanceTo(a);
          final db = distanceTo(b);
          // Cars with no location sink to the bottom rather than to the top.
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });
    }

    return result;
  }

  @override
  List<Object?> get props => [
        search,
        minPrice,
        maxPrice,
        seats,
        transmissions,
        fuelTypes,
        availableOnly,
        sort,
      ];
}
