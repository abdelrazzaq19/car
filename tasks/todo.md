# Task List

Derived from `tasks/plan.md`. Each task states its acceptance criteria and how to verify it.
Dependencies are listed as task ids; a task may start once its dependencies are done.

---

## Phase 0 — Stop the bleeding

### T0.1 — Fix crash-class defects
Depends on: nothing

- [x] `car_details_page.dart` — `dispose()` calls `_controller!.dispose()`; remove the listener before disposing.
- [x] `data/models/car.dart` — add a numeric coercion helper so `int`, `double`, `String` and `null` all parse; default missing fields rather than throwing.
- [x] `injection_container.dart` — guard every registration with `isRegistered`; replace `throw e` with `rethrow`.
- [x] `main.dart` — remove the four unused imports.

Acceptance criteria
- A Firestore document with `distance: 300` (an int) parses without throwing.
- A document missing `fuelCapacity` parses to a default instead of throwing.
- Calling `initInjection()` twice does not throw.
- Navigating into and straight back out of the details page logs no "setState called after dispose".

Verify: `flutter analyze` reports zero warnings; `flutter test`; manual hot restart twice.

### T0.2 — Real tests
Depends on: T0.1

- [x] Delete the generated counter test.
- [x] `test/data/models/car_test.dart` — int, double, string, missing and null inputs.
- [x] `test/presentation/bloc/car_bloc_test.dart` — a fake `GetCars` covering the loaded and error paths.

Acceptance criteria: `flutter test` passes with at least six assertions and no skipped tests.
Verify: `flutter test`.

### T0.3 — Layout fixes
Depends on: nothing

- [x] `CarDetailsPage` body wrapped in `SingleChildScrollView` (or converted to `CustomScrollView`).
- [x] Onboarding copy given horizontal padding; the CTA becomes `double.infinity` inside a padded parent.

Acceptance criteria: no RenderFlex overflow at 320x568; onboarding text is not flush to the edge at any width from 320 to 1024.
Verify: run at 320x568 and at tablet size; check the console for overflow warnings.

**Checkpoint A — DONE** — analyze clean, tests green, all four screens navigable. Pause for review.

---

## Phase 1 — Foundation

### T1.1 — Dependency upgrade
Depends on: Checkpoint A

- [x] Upgrade firebase_core, cloud_firestore, flutter_map, bloc, get_it, flutter_bloc.
- [x] Migrate `MapOptions(center:, zoom:)` to `initialCenter:` / `initialZoom:`.
- [x] Add shared_preferences, intl, cached_network_image, equatable, google_fonts, shimmer.
- [ ] Add firebase_auth and geolocator — deferred to Phase 2 / T3.3, where they are first used.
- [ ] Add go_router — see T1.3 below.

Acceptance criteria: `flutter pub outdated` shows no direct dependency a major version behind; the map renders and pans.
Verify: `flutter pub get`, `flutter analyze`, run the app and open the map page.

### T1.2 — Design system and dark mode
Depends on: T1.1

- [x] `lib/core/theme/app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart`.
- [x] Light and dark `ThemeData` built from a single seed.
- [x] `ThemeCubit` persisted via `shared_preferences`; a toggle in the app bar or settings.
- [x] Replace hardcoded colours in all four pages and both widgets.

Acceptance criteria: both themes render every screen legibly and the choice survives a restart.

Deviation from the original criterion: literal colours remain in three places,
deliberately. White text and pins sit on a photo, a map tile layer and a dark
scrim, all of which stay dark in either theme, so a scheme colour would be
wrong there; and the shimmer skeleton needs an opaque mask colour. Every other
surface reads from `Theme.of(context).colorScheme`.
Verify: grep for colour literals; screenshots in light and dark.

### T1.3 — Routing — NOT DONE, deferred
Depends on: T1.1

- [ ] `go_router` config with named routes for onboarding, list, detail, map.
- [ ] Replace every `Navigator.push`.

Deferred deliberately: routing is only worth changing once there are screens
worth deep-linking to (booking, My Bookings), which arrive in Phase 2. The app
still uses `Navigator.push`.

Acceptance criteria: each screen is reachable by route name; the Android back button behaves correctly.
Verify: navigate the whole app; test deep links via `adb shell am start`.

### T1.4 — Widen the Car model
Depends on: T1.2

- [x] Add `id`, `imageUrl`, `location`, `seats`, `transmission`, `fuelType`, `pricePerDay`, `rating`, `available`.
- [x] Add `Equatable`; add `toMap`.
- [x] Data source reads `doc.id` into `id`.
- [x] Settle on one price unit; update every label.
- [x] Seed script or fixture documenting the Firestore schema.

Acceptance criteria: all new fields tolerate absence; the price unit is identical on every screen; `Car` instances compare by value.
Verify: extend `car_test.dart`; run against seeded data.

**Checkpoint B — DONE except T1.3** — builds on the new dependencies, both themes correct, screens work against the widened model. Routing deferred to Phase 2.

---

## Phase 2 — Core rental journey

### T2.1 — Auth
Depends on: Checkpoint B

- [x] Anonymous sign-in on launch; `AuthBloc`; an account screen; optional email-link upgrade.

Acceptance criteria: a `uid` is available before any booking write; the same `uid` survives a restart.
Verify: sign in, restart, confirm the uid is unchanged.

### T2.2 — Rental period and pricing
Depends on: T1.4

- [x] `RentalPeriod` value object with validation (end after start, minimum one day).
- [x] `PriceQuote` calculator: base, fees, deposit, total.
- [x] A date-range picker sheet on the detail page with a live breakdown.

Acceptance criteria: a three-day booking at 50 per day yields a base of 150; an end before the start is rejected with a clear message; the breakdown updates as the dates change.
Verify: unit tests for the calculator, including boundary cases; widget test for the picker.

### T2.3 — Booking write and availability
Depends on: T2.1, T2.2

- [x] `Booking` model and `BookingRepository`; an overlap query; a `BookingBloc`; a confirmation screen with a reference code.

Acceptance criteria: a booking appears in Firestore with the car id, uid, period, quote and status; a second overlapping booking for the same car is rejected with a clear message.
Verify: unit tests for the overlap logic; an end-to-end booking against the emulator.

### T2.4 — My Bookings
Depends on: T2.3

- [x] Upcoming and past tabs, status chips, cancel behind a confirmation dialog.

Acceptance criteria: a new booking appears under Upcoming; cancelling sets the status to cancelled and frees the dates for rebooking.
Verify: book, cancel, rebook the same range.

**Checkpoint C — DONE** — the full booking journey works and double-booking is prevented. Pause for review.

---

## Phase 3 — Discovery and polish

### T3.1 — Search, filter, sort
Depends on: Checkpoint C

- [ ] `CarQuery` value object; filter events on `CarBloc`; a search bar and a filter sheet.

Acceptance criteria: typing narrows the list; filters combine; clearing restores the full list; an empty result shows an empty state, not a blank screen.
Verify: widget tests covering each filter and their combination.

### T3.2 — Favourites
Depends on: T2.1

- [ ] A per-user subcollection; a heart toggle on the card; a favourites tab.

Acceptance criteria: the toggle persists across restarts and is scoped to the signed-in user.
Verify: toggle, restart, confirm.

### T3.3 — Real map
Depends on: T1.4

- [x] Markers from Firestore locations (done early: the flutter_map v8 migration forced this file open anyway).
- [ ] User location via geolocator with permission handling; distance sort; an "open in maps" action.
- [x] Remove the fabricated `MoreCard` data; source similar cars from the repository.

Acceptance criteria: each car appears at its own coordinates; denying the location permission degrades gracefully rather than crashing; no fabricated model strings remain.
Verify: run with the permission granted and denied; grep for `+ '-1'`.

### T3.4 — Loading, error and offline states
Depends on: Checkpoint C

- [x] Skeleton loaders; pull-to-refresh; a typed error mapper with retry; Firestore offline persistence.
- [ ] A connectivity banner.

Acceptance criteria: no raw `e.toString()` reaches the UI; airplane mode shows cached cars plus a banner; retry re-fetches.
Verify: airplane-mode run; force an error and confirm retry works.

### T3.5 — Images
Depends on: T1.4

- [x] `cached_network_image` with placeholder and error fallback; a `Hero` transition from list to detail.

Acceptance criteria: a broken URL shows the fallback rather than a red error box; the hero animation does not flicker.
Verify: seed a broken URL; record the transition.

### T3.6 — Accessibility
Depends on: T3.1 to T3.5

- [ ] Semantics labels on icon-only controls; 48dp minimum tap targets; a contrast check; text-scale testing.

Acceptance criteria: every interactive element is reachable by TalkBack with a meaningful label; no layout breaks at text scale 2.0.
Verify: TalkBack pass; run at text scale 2.0; a contrast checker on both themes.

**Checkpoint D** — final pass. Analyze clean, tests green, both themes, phone and tablet, offline verified.
