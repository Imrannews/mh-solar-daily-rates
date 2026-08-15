# MH Solar Daily Rates

Flutter Android app for MH Solar & Electronics, Sialkot.

## Current features
- Live solar rates from Firebase Firestore (`solar_rates`)
- Search by brand, model, watt and category
- Category filters
- Share daily rates
- WhatsApp contact
- Secure Firebase email/password admin login
- Admin add, edit and delete rates
- Automatic Android APK build with GitHub Actions

## Firestore
`solar_rates` fields:
- `brand` — string
- `model` — string
- `watt` — number
- `price` — number
- `category` — string
- `updatedAt` — timestamp (added by the admin panel)

Admin collection:
- Collection: `admins`
- Document ID: Firebase Authentication user UID
- Field: `role` = `admin`

After changing `firestore.rules` in GitHub, publish the same rules in Firebase Console → Firestore Database → Rules.

Never commit passwords, service-account keys, or other private credentials.
