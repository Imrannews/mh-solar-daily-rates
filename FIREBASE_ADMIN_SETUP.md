# MH Solar Admin Setup

The Flutter app now includes an authenticated admin panel for managing `solar_rates`.

## 1. Enable Email/Password authentication

Firebase Console → Authentication → Get started → Sign-in method → Email/Password → Enable → Save.

## 2. Create the admin user

Firebase Console → Authentication → Users → Add user.

Create your private admin email/password. Do not put the password in GitHub.

Copy the new user's **UID**.

## 3. Authorize the user as MH Solar admin

Firebase Console → Firestore Database → Data → create/open collection:

`admins`

Create a document whose **Document ID is exactly the admin user's UID**.

Optional fields:

- `name`: `MH Solar Admin`
- `role`: `admin`

The app checks that `admins/{uid}` exists before allowing rate management.

## 4. Admin features

From the app Home screen, tap the **admin shield icon**.

After login you can:

- Add a solar rate
- Edit a rate
- Delete a rate
- Set brand, model, watt, price and category
- See update time

Changes are written directly to Firestore collection `solar_rates` and appear live in the customer app.

## Security note

Before public Play Store release, replace Firestore Test Mode rules with production rules that allow public read access to `solar_rates` but restrict writes to authenticated admin users. Do not publish with open write rules.
