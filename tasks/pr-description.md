# Title

fix: Android build, booking status, security rules and CI

# Body

Closes the gaps between "the plan is done" and "this could take a real booking".
Four of these were not in the plan; they surfaced from actually trying to build
and run the thing.

## The Android build was broken, not merely unverified

Gradle 7.6.3 cannot run on the Java 25 Flutter uses here, and Firebase 4.x needs
AGP 8+. Now on Gradle 9.1.0, AGP 8.13.0, Kotlin 2.3.20, google-services 4.4.4,
and Java 11 source/target. `flutter build apk --debug` succeeds.

`android.newDsl=false` is deliberate: Flutter's tooling advises moving to AGP 9,
but the Gradle plugin in Flutter 3.47 still reads the legacy DSL and fails
casting `ApplicationExtensionImpl` to `AbstractAppExtension` under AGP 9. I tried
it and hit exactly that. Revisit when Flutter supports AGP 9.

## Bookings never ended

Nothing wrote `active` or `completed` — there is no scheduled job — so a rental
that finished last year still read "Confirmed" **and kept holding its dates
against a rebooking**. `Booking.statusAt(now)` derives both from the dates and
feeds the availability query, the My Bookings split, the status chip, and
whether cancel is offered.

The evaluation time travels on `MyBookingsLoaded.asOf` rather than each widget
calling `DateTime.now()`. The first attempt did the latter, and a test caught it
disagreeing with the cubit's injected clock.

## Security rules are now real files

`firestore.rules` and `firestore.indexes.json`, wired into `firebase.json`. They
deny by default, keep bookings private to their owner, refuse a client-written
`completed` status (which would free a car the client still holds), and freeze
dates, amounts and ownership after creation.

**They still have to be deployed** — merging this changes nothing in the
database:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

## Also

- Owner details come from Firestore (`ownerName`, `ownerPhotoUrl`,
  `ownerVerified`) instead of a hardcoded "naumanbutt2002 · Verified host" on
  every listing. A listing with no owner named shows a neutral placeholder
  rather than inventing a person.
- CI runs the format check, `analyze --fatal-infos`, the tests, and both the
  debug APK and web builds on every push and pull request.
- Gradle output under `android/` is now ignored; the root `/build/` rule missed
  it because `android/build.gradle` redirects `buildDir`.

## For the reviewer

- Tests 176 to 188. Format check clean, analyze clean at `--fatal-infos`, web
  and Android both build.
- **Not addressed: payment.** The price breakdown says "charged today" and
  nothing is charged. Needs a payment provider account and a scope decision.
- Still needing a device: TalkBack, a contrast check, an airplane-mode run, and
  a live booking against Firestore with anonymous sign-in enabled.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
