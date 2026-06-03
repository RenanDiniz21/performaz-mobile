# Performaz Mobile

Flutter seller app for the Performaz platform.

The mobile app is currently scoped for the external seller. Managers should use the web admin panel; manager login in mobile redirects to a handoff screen instead of showing mock manager modules.

## Current Seller Features

- Login with seller matricula and password.
- Route of the day from the API.
- Client detail and route stop status.
- Check-in with route-specific API submission.
- Product catalog loaded from the API.
- Cart and order submission.
- No-sale visit registration with a required reason.
- Gamification dashboard, achievements, goals, and leaderboard.
- Profile hydration from the API after login.
- Profile edit for name and phone.
- Password change with current password confirmation.
- Offline persistence/sync structure for check-ins and orders.

## Demo Login

Seeded seller:

- Matricula: `V001`
- Password: `vendor123`

Other seeded sellers:

- `V002`, `V003`, `V004`, `V005`
- Password: `vendor123`

## Running Locally

Install dependencies:

```bash
flutter pub get
```

Run on Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3333/api
```

Run on Windows desktop:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3333/api
```

The API default inside the app is `http://localhost:3333/api`, which works for desktop but not for Android emulator networking.

## Tests

```bash
flutter test
flutter analyze
```

Current baseline:

- 35 Flutter tests.
- Analyzer clean.

## Architecture

Main folders:

- `lib/app`: app shell, routing, dependency injection, theme.
- `lib/core`: auth, networking, repositories, local database, sync.
- `lib/features/auth`: login, forgot password, profile.
- `lib/features/routes`: route list, client detail, check-in.
- `lib/features/orders`: catalog, cart, order summary, no-sale.
- `lib/features/gamification`: XP dashboard, achievements, leaderboard.
- `lib/shared`: models and reusable widgets.

State management uses `flutter_bloc`; networking uses `Dio`; local persistence uses `Drift`.

## Honest Limitations

Not finished yet:

- Password recovery email flow.
- Google login.
- Self-registration.
- Push notification delivery on real devices.
- Full real-device offline sync validation.
- Avatar/profile photo update.
- Native mobile manager module.

The app now shows explicit unavailable states for unfinished auth actions instead of fake success.
