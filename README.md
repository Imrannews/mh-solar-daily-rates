# MH Solar Daily Rates ☀️

Flutter Android app for **MH Solar & Electronics** to publish live daily solar market rates.

## Firebase

The app is connected to Firebase project `mh-solar-daily-rates` and reads live data from Cloud Firestore.

### Firestore collection

Collection: `solar_rates`

Each document should contain:

- `brand` — string, e.g. `Jinko Solar`
- `model` — string, e.g. `585W N-Type`
- `watt` — number, e.g. `585`
- `price` — number, e.g. `24500`
- `category` — string, e.g. `Solar Panel`

The app listens to `solar_rates` with a live Firestore stream, so changing a rate in Firebase updates the app automatically without publishing a new APK.

## Development

```bash
flutter pub get
flutter run
```

Package: `pk.mhsolar.dailyrates`

## Current implementation

- Firebase Core initialization
- Cloud Firestore integration
- Hard-coded demo rates removed
- Live `solar_rates` listener
- Loading, empty and Firestore error states
- Pull-to-refresh
- Share current Firebase rates
- WhatsApp contact button
- Android/Play Store development target

## Security

Do not commit private service-account credentials to GitHub. The Android Firebase client configuration is intended for client-side use; Firestore Security Rules must still be configured before production release.
