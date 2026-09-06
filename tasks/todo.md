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
- [x] Add go_router — see T1.3 below.

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

### T1.3 — Routing — DONE
Depends on: T1.1

- [x] `go_router` config with named routes for onboarding, list, detail, map,
      bookings and booking confirmation.
- [x] Replaced every `Navigator.push`. The remaining `Navigator.pop` calls are
      dialogs and modal sheets returning a value, which are not routes.

Car detail and its map are addressed by car id (`/cars/:carId`), not by passing
a `Car` object, so a link survives a cold start. `_CarRoute` resolves the id
against the loaded list: it waits while the list is still loading rather than
showing "not found" for a car that exists, and shows a proper not-found screen
for an id that does not.

The booking confirmation route carries its `Booking` in `extra` and falls back
to the bookings list when opened cold, since a receipt has nothing to show
without one.

Verified: 14 router tests covering deep links, unknown ids, unmatched paths, the
cold-link wait, back navigation and the confirmation fallback. Also checked in a
browser against live Firestore — `/#/cars` loads real data and the URL tracks
the route.

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

**Checkpoint B — DONE** — builds on the new dependencies, both themes correct, screens work against the widened model. Routing (T1.3) landed after Phase 3.

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

- [x] `CarQuery` value object; filter events on `CarBloc`; a search bar and a filter sheet.

Acceptance criteria: typing narrows the list; filters combine; clearing restores the full list; an empty result shows an empty state, not a blank screen.
Verify: widget tests covering each filter and their combination.

### T3.2 — Favourites
Depends on: T2.1

- [x] A per-user subcollection; a heart toggle on the card; a favourites tab.

Acceptance criteria: the toggle persists across restarts and is scoped to the signed-in user.
Verified in tests against a fake repository, including the optimistic rollback
when the write fails. Not yet verified against live Firestore.

### T3.3 — Real map
Depends on: T1.4

- [x] Markers from Firestore locations (done early: the flutter_map v8 migration forced this file open anyway).
- [x] User location via geolocator with permission handling; distance sort; an "open in maps" action.
- [x] Remove the fabricated `MoreCard` data; source similar cars from the repository.

Acceptance criteria: each car appears at its own coordinates; denying the location permission degrades gracefully rather than crashing; no fabricated model strings remain.
Denial and permanent-block paths are covered by tests over a fake location
service. A run on a real device with the permission granted and denied has NOT
been done.

### T3.4 — Loading, error and offline states
Depends on: Checkpoint C

- [x] Skeleton loaders; pull-to-refresh; a typed error mapper with retry; Firestore offline persistence.
- [x] A connectivity banner.

Acceptance criteria: no raw `e.toString()` reaches the UI; airplane mode shows cached cars plus a banner; retry re-fetches.
The error mapping and retry are covered by tests. The airplane-mode run on a
real device has NOT been done.

### T3.5 — Images
Depends on: T1.4

- [x] `cached_network_image` with placeholder and error fallback; a `Hero` transition from list to detail.

Acceptance criteria: a broken URL shows the fallback rather than a red error box; the hero animation does not flicker.
The fallback path is in code; the broken-URL run and the hero recording have NOT
been done.

### T3.6 — Accessibility
Depends on: T3.1 to T3.5

- [x] Semantics labels on icon-only controls (tooltips, asserted in tests).
- [x] 48dp minimum tap targets (asserted in tests).
- [x] Text-scale testing at 2.0 and a 320px width (asserted in tests).
- [ ] Contrast check on both themes — NOT DONE. Colours come from a single M3
      seed, which gives reasonable contrast by construction, but no checker has
      been run over the rendered screens.
- [ ] TalkBack pass on a device — NOT DONE. Only the automated semantics
      assertions have run.

A genuine defect was found and fixed here: the card's `Semantics` label was
swallowing the favourite button, so a screen reader could not reach the heart
separately. The heart is now a sibling of the tappable card, not a descendant.

**Checkpoint D — code complete, device verification outstanding.**
Analyze reports zero issues, 162 tests pass, and the web target builds. What has
NOT been verified: a run against live Firestore, airplane-mode behaviour,
TalkBack, and a contrast checker. Those need a device and a configured Firebase
project with anonymous sign-in enabled.


---

## Post-plan hardening

Work done after Phase 3, closing gaps that the plan never covered.

### Booking status without a server — DONE

- [x] `Booking.statusAt(now)` derives `active` and `completed` from the dates.

Nothing ever wrote those statuses — there is no scheduled job — so a rental that
finished last year still read "Confirmed" and, worse, kept holding its dates
against a rebooking through `blocksAvailability`. The derivation now feeds the
availability query, the My Bookings split, the status chip and whether cancel is
offered.

The evaluation time is carried on `MyBookingsLoaded.asOf` rather than each
widget calling `DateTime.now()`, so the UI and the split cannot disagree and the
clock stays injectable in tests. Ten tests cover the transitions.

### Security rules — WRITTEN, NOT DEPLOYED

- [x] `firestore.rules` and `firestore.indexes.json`, wired into `firebase.json`.
- [ ] **Deploy them.** Until `firebase deploy --only firestore:rules` is run, the
      database uses whatever the console has, which for a new project is often
      wide open.

### Owner data — DONE

- [x] `ownerName`, `ownerPhotoUrl` and `ownerVerified` on `Car`, read from
      Firestore. Absent shows "Listed by the fleet" instead of the hardcoded
      "naumanbutt2002 · Verified host" that appeared on every car.

### Android build — FIXED

- [x] The Android build was broken outright: Gradle 7.6.3 cannot run on the
      Java 25 that Flutter uses here, and Firebase 4.x needs AGP 8+.

Now on Gradle 9.1.0, AGP 8.13.0, Kotlin 2.3.20, google-services 4.4.4, Java 11
source/target. `flutter build apk --debug` succeeds.

Note `android.newDsl=false` is deliberate: Flutter 3.47's Gradle plugin still
reads AGP's legacy DSL and fails casting `ApplicationExtensionImpl` to
`AbstractAppExtension` under AGP 9. Revisit when Flutter supports AGP 9.

### CI — DONE

- [x] `.github/workflows/ci.yml`: format check, `analyze --fatal-infos`, tests,
      plus debug APK and web builds on every push and pull request.

### Still open

- [ ] **Payment.** The breakdown shows "charged today" and nothing is charged.
      Needs a provider account and a decision on scope.
- [ ] Deploy the security rules (above).
- [ ] Run the booking flow against live Firestore with anonymous sign-in enabled.
- [ ] TalkBack, contrast check and airplane-mode run on a device.
- [ ] Localisation; strings are hardcoded English.
- [ ] Real car photos; every card falls back to the bundled asset.
