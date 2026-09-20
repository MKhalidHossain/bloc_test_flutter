# bloc_test_flutter

**A Flutter Clean Architecture reference: BLoC + Dio + Retrofit, with silent JWT refresh and a bundled Dart mock API server.**

This repo is a small, runnable demonstration of how I structure production Flutter apps — feature-first Clean Architecture, BLoC for state, `dartz` for typed error handling, Retrofit-generated API clients over Dio, and an interceptor chain that transparently refreshes expired access tokens without the UI ever knowing.

It ships with its own **Dart Shelf mock API server** in `bin/`, so you can clone it and run the full login → token → refresh → 401 flow end to end with zero external setup.

<p>
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.12-0175C2?logo=dart&logoColor=white">
  <img alt="State management" src="https://img.shields.io/badge/State-BLoC%209.x-8A2BE2">
  <img alt="Architecture" src="https://img.shields.io/badge/Architecture-Clean-success">
</p>

---

## Why this repo exists

Most "Clean Architecture in Flutter" samples stop at a folder structure. This one focuses on the part that actually bites you in production: **auth lifecycle**.

- What happens when the access token expires mid-session?
- What happens when *five* requests get a 401 at the same time?
- Where does token storage live so the domain layer never learns about it?

The `RefreshTokenInterceptor` in this repo answers those: it refreshes once, queues every concurrent failure behind a `Completer`, replays them with the new token, and logs the user out only when the refresh itself fails.

---

## Architecture

Feature-first, three layers, dependencies pointing inward. The domain layer imports nothing from `data/` or `presentation/`.

```
lib/
├── core/                                  # Cross-feature infrastructure
│   ├── constants/                         # API paths, storage keys
│   ├── error/failure.dart                 # Sealed-style Failure hierarchy
│   ├── network/
│   │   ├── dio_client.dart                # BaseOptions + interceptor wiring
│   │   ├── auth_api_service.dart          # @RestApi — Retrofit definitions
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart      # Injects Bearer token
│   │       ├── logging_interceptor.dart   # Debug-only request/response log
│   │       └── refresh_token_interceptor.dart  # Silent refresh + retry queue
│   ├── Storage/secure_storage_service.dart# Keychain / EncryptedSharedPrefs
│   ├── usecase/usecase.dart               # UseCase<Type, Params> contract
│   └── utils/api_response.dart            # Generic ApiResponse<T> envelope
│
├── feature/auth/
│   ├── domain/                            # Pure Dart — no Flutter, no Dio
│   │   ├── entitys/user_entities.dart
│   │   ├── repository/auth_repository.dart
│   │   └── usecase/                       # Login, Logout, GetCachedUser
│   ├── data/
│   │   ├── models/                        # JSON ⇄ entity mapping
│   │   ├── datasource/                    # Remote (Retrofit) + local (secure)
│   │   └── repository/auth_repository_impl.dart
│   └── presentation/
│       ├── bloc/                          # AuthBloc / Event / State
│       └── screens/login_screen.dart
│
└── main.dart                              # Composition root — manual DI
```

**Layer rules enforced by the code:**

| Layer | Knows about | Returns |
| --- | --- | --- |
| `presentation` | domain use cases only | `AuthState` |
| `domain` | abstractions only | `Either<Failure, T>` |
| `data` | Dio, Retrofit, secure storage | models → entities |

Errors never cross a layer as exceptions. `AuthRepositoryImpl` catches `DioException`, maps it to a `ServerFailure` / `CacheFailure` / `UnknownFailure`, and hands the BLoC an `Either` — so the presentation layer has exactly two branches to render and no `try/catch` anywhere.

---

## Tech stack

| Concern | Choice |
| --- | --- |
| State management | `bloc` / `flutter_bloc` 9.x, `equatable` for value states |
| Networking | `dio` 5.x + `retrofit` 4.x (codegen via `build_runner`) |
| Error handling | `dartz` — `Either<Failure, T>` across every boundary |
| Secure storage | `flutter_secure_storage` (Keychain, EncryptedSharedPreferences) |
| Serialization | `json_serializable` / `json_annotation` |
| Connectivity | `connectivity_plus` |
| Mock backend | `shelf`, `shelf_router`, `shelf_cors_headers`, `uuid` |

---

## The auth flow

```
LoginRequested
   └─ AuthBloc → LoginUsecase → AuthRepository
        └─ AuthRemoteDataSource → Retrofit → Dio
             ├─ AuthInterceptor      (skips /auth/login and /auth/refresh)
             ├─ LoggingInterceptor   (kDebugMode only)
             └─ RefreshTokenInterceptor
        └─ tokens + user persisted to secure storage
   └─ emit AuthSuccess(user)  |  AuthFailureState(message)
```

### Silent token refresh

When any authenticated call returns `401`:

1. The first failure sets `_isRefreshing` and calls `/auth/refresh` on a **clean Dio instance** (no interceptors — avoids infinite recursion).
2. Every other in-flight 401 parks on a `Completer` in `_pendingRequests` instead of firing its own refresh.
3. On success, new tokens are written to secure storage, all pending completers resolve, and every original request is replayed with the fresh `Authorization` header via `handler.resolve()`.
4. On failure, tokens are cleared and the error propagates so the app can route back to login.

The user sees one uninterrupted session. The BLoC never sees a 401.

---

## Running it

### 1. Start the mock API

```bash
dart pub get
dart run bin/server.dart
# → Mock API server running at http://localhost:8080
```

Seed it with sample data:

```bash
curl http://localhost:8080/admin/seed
```

### 2. Run the app

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

The Android emulator resolves `localhost` as `10.0.2.2`; that is handled in `ApiConstants`. For a physical device, point it at your machine:

```dart
ApiConstants.overrideBaseUrl = 'http://192.168.x.x:8080';
```

Any non-empty username and password logs in against the mock server.

---

## Mock API reference

| Method | Endpoint | Purpose |
| --- | --- | --- |
| `POST` | `/auth/login` | Returns access + refresh token, `expires_in`, user |
| `POST` | `/auth/refresh` | Rotates both tokens |
| `POST` | `/auth/logout` | Invalidates the current token |
| `GET` | `/bookings` | Cursor-paginated list (`limit`, `cursor`) |
| `POST` | `/bookings` | Creates a booking; `409` on double-booking a doctor |
| `DELETE` | `/bookings/{id}` | Soft-cancels a booking |
| `GET` | `/pending-sync` | Inspect the mock email job queue |
| `GET` | `/admin/seed` | Load 25 sample bookings |
| `GET` | `/admin/expire-token` | Force the next request to return `401` |
| `GET` | `/admin/reset` | Wipe and reseed state |

### Testing the refresh path by hand

```bash
curl http://localhost:8080/admin/seed
# log in from the app, then:
curl http://localhost:8080/admin/expire-token
# pull to refresh in the app — the interceptor refreshes and retries silently
```

Access tokens live for 300 seconds, so you can also just wait it out.

---

## Roadmap

The mock server already exposes the booking domain; the Flutter side stops at auth. Next steps, in order:

- [ ] `booking` feature module mirroring the auth layer structure
- [ ] Cursor-based infinite scroll backed by a `BookingBloc`
- [ ] Offline queue for bookings created without connectivity (`connectivity_plus` is already a dependency)
- [ ] `get_it` + `injectable` to replace the manual composition root in `main.dart`
- [ ] Unit tests for use cases, `bloc_test` for `AuthBloc`, and a mocked `Dio` adapter for the refresh queue
- [ ] `go_router` with an auth guard, replacing the named-route push in `LoginScreen`

---

## Notes for reviewers

This started as a timeboxed assessment project, so a few rough edges are deliberate and tracked above rather than hidden:

- DI is wired by hand in `main.dart` — readable, and easy to swap for `get_it` later.
- `test/widget_test.dart` is still the Flutter counter template and does not compile against the current `MyApp` signature.
- The package is named `test` in `pubspec.yaml`, which shadows the `test` package; renaming it is a one-line change plus an import sweep.

---

## Author

**Md. Khalid Hossain** — Flutter Mobile App Developer

[Portfolio](https://khalid-hossain-portfolio.vercel.app) · [LinkedIn](https://linkedin.com/in/md-khalidhossain) · [GitHub](https://github.com/MKhalidHossain) · hossainkhalid93@gmail.com