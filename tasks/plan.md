# Car Rental App — Modernization Plan

Flutter 3.47 / Dart 3.13. Clean architecture (data / domain / presentation), BLoC + get_it, Firebase (Firestore), flutter_map.
No SPEC.md exists; this plan is derived from a read of `lib/`, `pubspec.yaml`, `flutter analyze`, and `test/`.

---

## 1. Current state

### Layout

```
lib/
  data/          models/car.dart, datasources/firebase_car_data_source.dart, repositories/car_repository_impl.dart
  domain/        repositories/car_repository.dart, usecases/get_cars.dart
  presentation/  bloc/bloc/{car_bloc,car_event,car_state}.dart
                 pages/{onboarding,car_list_screen,car_details,maps_detail}.dart
                 widgets/{car_card,more_card}.dart
  main.dart, injection_container.dart, firebase_options.dart
```

### Dependency graph

```
main.dart
  |- injection_container --> FirebaseFirestore
  |     |- FirebaseCarDataSource --> CarRepositoryImpl --> GetCars --> CarBloc
  |- OnboardingPage --> CarListScreen --> CarCard --> CarDetailsPage --> MapsDetailPage
                                                       |- MoreCard
```

Everything funnels through the single `Car` model, so model changes ripple to every page. `Car` is therefore the root of the dependency graph and must be handled early.

---

## 2. Defects found

### Crash / correctness (must fix)

| # | Location | Defect |
|---|----------|--------|
| D1 | `car_details_page.dart:41` | `dispose()` calls `_controller!.forward()` instead of `_controller!.dispose()`. The AnimationController is never released and its listener calls `setState` after unmount. Leak, plus "setState called after dispose" on fast back-navigation. |
| D2 | `data/models/car.dart:16-21` | `Car.fromMap` casts implicitly. Firestore stores whole numbers as `int`, so a document with `distance: 300` throws `type 'int' is not a subtype of type 'double'`. A missing or null field throws a null-cast error. Every list load dies on one bad document. |
| D3 | `injection_container.dart` | `initInjection()` is not idempotent — a hot restart re-registers and get_it throws `ArgumentError: Object/factory with type ... is already registered`. Also `throw e` loses the stack trace (`use_rethrow_when_possible`). |
| D4 | `test/widget_test.dart` | Still the generated counter test. `flutter test` fails; there is no real coverage. |
| D5 | `car_details_page.dart` | `body: Column` holding a card, a 170px row and three `MoreCard`s is unscrollable — RenderFlex overflow on any phone under roughly 800 logical pixels. |
| D6 | `main.dart` | Four unused imports (`car_details_page`, `car_list_screen`, `maps_detail_page`, `cloud_firestore`); 40 analyzer issues in total. |

### UX / product defects

| # | Defect |
|---|--------|
| D7 | "Book Now" (`maps_detail_page.dart`) is `onPressed: () {}` — the app's primary action does nothing. |
| D8 | `MapsDetailPage` hardcodes `LatLng(32.4935378, 74.5411575)` for every car; `Car` carries no location. The map is decoration, not information. |
| D9 | `MoreCard` renders fabricated data (`model + '-1'`, `distance + 100`) and the "-3" suffix is duplicated by a copy-paste slip. |
| D10 | `Car` has no `id`. Nothing can be booked, favourited or deep-linked. |
| D11 | Price reads `/h` in `car_card.dart` but `/day` in `maps_detail_page.dart` for the same field. |
| D12 | No search, no filter, no sort. Unusable past roughly ten cars. |
| D13 | No empty state, no retry on error, no pull-to-refresh. `CarsError` shows a raw `e.toString()`. |
| D14 | Theme seeds `deepPurple` but every screen hardcodes `Colors.white` / `Colors.black` / `0xffF3F3F3`. No dark mode, no design tokens, no typography scale. |
| D15 | Onboarding copy has no horizontal padding — text sits flush against the screen edge; the CTA is a hardcoded 320px wide and clips on small devices. |
| D16 | Every car shows the same `assets/car_image.png`. No image from Firestore, no loading or error placeholder, no `Hero` continuity between list and detail. |
| D17 | No accessibility work: no semantics labels, tap targets under 48dp, contrast unverified. |

### Dependency risk

`firebase_core ^2.24.2`, `cloud_firestore ^4.14.0` and `flutter_map ^4.0.0` are several majors behind what Flutter 3.47 expects. `flutter_map` v4's `MapOptions(center:, zoom:)` was replaced by `initialCenter:` / `initialZoom:` in v6 and later. Upgrading is a prerequisite for the map features and is treated as its own checkpointed task.

---

## 3. Features to add

Chosen for real rental utility, ordered by value per unit of work.

- **F1 — Rental period picker and real price maths.** Pick start and end date-time, see days, subtotal, fees, deposit and total. This is what makes the app a rental app rather than a catalogue.
- **F2 — Booking flow persisted to Firestore.** A `bookings` collection, a confirmation screen, a booking reference.
- **F3 — My Bookings.** Upcoming and past tabs, status (pending / confirmed / active / completed / cancelled), cancel action behind a confirmation dialog.
- **F4 — Auth (Firebase Auth).** Anonymous by default, upgradeable to email link, so bookings have an owner. Required for F2 and F3 to be meaningful.
- **F5 — Availability check.** Reject an overlapping booking for the same car before writing.
- **F6 — Search, filter, sort.** Free text on model, filters for price range, seats, transmission and fuel; sort by price or distance.
- **F7 — Favourites.** Per-user saved cars.
- **F8 — Real map.** Per-car `GeoPoint` from Firestore, one marker per car, user location via `geolocator`, straight-line distance, and an "open in maps" hand-off.
- **F9 — Material 3 design system and dark mode.** Tokens, typography scale, shared components, and a system/light/dark switch persisted with `shared_preferences`.
- **F10 — Offline and connectivity.** Firestore offline persistence, an offline banner, skeleton loaders in place of a bare spinner.

---

## 4. Vertical slices

Each task is one complete path from data through to a screen the user can operate — not a horizontal "all models first, then all widgets" layering.

### Phase 0 — Stop the bleeding

- **T0.1** Fix D1, D2, D3 and D6. Harden `Car.fromMap` with a numeric coercion helper and defaults; make `initInjection` idempotent; correct `dispose()`; remove unused imports.
- **T0.2** Replace `test/widget_test.dart` with real tests: `Car.fromMap` against int, double, missing and null inputs, plus a `CarBloc` test with a fake `GetCars`.
- **T0.3** Wrap the `CarDetailsPage` body in a scroll view (D5); pad the onboarding copy and make the CTA width responsive (D15).

**Checkpoint A:** `flutter analyze` reports zero warnings, `flutter test` is green, and the app runs and navigates end to end.

### Phase 1 — Foundation

- **T1.1** Dependency upgrade: firebase_core, cloud_firestore, flutter_map (including its v6 `initialCenter` / `initialZoom` API migration), bloc and get_it. Add `firebase_auth`, `shared_preferences`, `intl`, `geolocator`, `cached_network_image`, `equatable` and `go_router`.
- **T1.2** Design system (F9): `lib/core/theme/` holding the colour scheme, typography, spacing, radii and elevation; light and dark `ThemeData`; a `ThemeCubit` persisted to `shared_preferences`. Replace hardcoded colours screen by screen.
- **T1.3** Routing: replace imperative `Navigator.push` calls with `go_router` so car detail and booking become deep-linkable.
- **T1.4** Widen the `Car` model (D10, D8, D11, D16): `id`, `imageUrl`, `location: GeoPoint`, `seats`, `transmission`, `fuelType`, `pricePerDay`, `rating`, `available`. Settle on one price unit and use it everywhere. Add `Equatable`. Update the Firestore data source to read `doc.id`.

**Checkpoint B:** the app builds on the new dependency set, both themes render correctly, and the existing screens still work against the widened model.

### Phase 2 — Core rental journey

- **T2.1** Auth (F4): anonymous sign-in on launch, an `AuthBloc`, an account screen, optional email-link upgrade.
- **T2.2** Rental period and pricing (F1): a `RentalPeriod` value object, a `PriceQuote` calculator (`days * pricePerDay + fees + deposit`) with unit tests, a date-range picker sheet on the detail page, and a live price breakdown.
- **T2.3** Booking write (F2, F5): a `Booking` model, a `BookingRepository`, an availability query over overlapping ranges, a `BookingBloc`, and a confirmation screen with a reference code.
- **T2.4** My Bookings (F3): upcoming and past tabs, status chips, cancel behind a confirmation.

**Checkpoint C:** a user can pick a car, choose dates, see a correct total, book, and find it in My Bookings. Two overlapping bookings for one car are rejected.

### Phase 3 — Discovery and polish

- **T3.1** Search, filter and sort (F6): a `CarQuery` value object, filter events on `CarBloc`, a search bar and a filter bottom sheet.
- **T3.2** Favourites (F7): a per-user subcollection, a heart toggle on the card, a favourites tab.
- **T3.3** Real map (F8): markers from Firestore locations, user location, distance sort, and an "open in maps" action. Delete the fabricated `MoreCard` data (D9) and replace it with genuinely similar cars drawn from the repository.
- **T3.4** Loading and error states (D13, F10): skeleton loaders, pull-to-refresh, a typed error mapper with a retry button, Firestore offline persistence, and a connectivity banner.
- **T3.5** Images (D16): `cached_network_image` with placeholder and error fallback, and a `Hero` transition from list to detail.
- **T3.6** Accessibility (D17): semantics labels, 48dp minimum tap targets, a contrast check, and testing at text scale 2.0.

**Checkpoint D:** a full pass — analyze clean, tests green, both themes, small-phone and tablet layouts, and offline behaviour verified.

---

## 5. Verification per phase

- **Phase 0:** `flutter analyze` (0 issues), `flutter test`, manual navigation of all four screens.
- **Phase 1:** `flutter pub outdated` shows no majors behind; screenshots in light and dark; the map still renders after the v6 migration.
- **Phase 2:** unit tests for the price calculator and the overlap check; an integration test covering pick car, choose dates, book, and appears in My Bookings.
- **Phase 3:** widget tests for filtering; an airplane-mode check for offline behaviour; an accessibility scan plus text scale 2.0.

---

## 6. Decisions taken

1. **Scope.** Phase 0 and Phase 1 now — crash fixes, tests, dependency upgrade, design system and the widened model. Phases 2 and 3 (booking backend, discovery) are a later pass.
2. **Price unit.** Per day. The field becomes `pricePerDay` and every label reads `/day`.
3. **Firestore schema.** The `cars` collection may be extended with `imageUrl`, `location`, `seats`, `transmission`, `fuelType` and `available`. All new fields tolerate absence, so existing documents keep working, and a seed script with sample data ships alongside.
4. **Auth.** Firebase anonymous sign-in, deferred to Phase 2 with the booking work.
5. **Dependency upgrade.** Upgrade now, as part of T1.1.
