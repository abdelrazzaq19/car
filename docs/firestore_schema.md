# Firestore schema

## Collection `cars`

The document id is the car id; the app reads it via `doc.id`, so no `id` field is needed inside the document.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `model` | string | yes | Display name. Falls back to "Unknown model". |
| `distance` | number | no | Range on a full tank or charge, in km. Defaults to 0. |
| `fuelCapacity` | number | no | Litres, or kWh when `fuelType` is `electric`. Defaults to 0. |
| `pricePerDay` | number | no | Daily rate. Defaults to 0. |
| `pricePerHour` | number | no | Legacy. Read only when `pricePerDay` is absent, so old documents keep working. |
| `imageUrl` | string | no | Remote photo. Falls back to the bundled asset when absent or broken. |
| `location` | geopoint | no | Pick-up point. `latitude` / `longitude` number fields are accepted as an alternative. |
| `seats` | number | no | Hidden from the specs row when 0. |
| `transmission` | string | no | `automatic` (or `auto`) / `manual`. Anything else reads as unknown and is hidden. |
| `fuelType` | string | no | `petrol` (or `gasoline`, `gas`) / `diesel` / `hybrid` / `electric` (or `ev`). |
| `rating` | number | no | 0 to 5. The badge is hidden when 0. |
| `reviewCount` | number | no | |
| `available` | boolean | no | Defaults to `true`. `false` disables booking and shows a "Booked" badge. |

### Parsing guarantees

- Numbers accept `int`, `double` and numeric strings. Firestore stores whole numbers as `int`, which used to crash the list load.
- Every field except `model` has a default, so adding fields never breaks existing documents.
- A document that fails to parse entirely is skipped rather than failing the whole query.

### Seeding

```bash
flutter run -t tool/seed_firestore.dart -d chrome
```

Writes five sample cars. Documents with matching ids are overwritten; everything else is left alone.
