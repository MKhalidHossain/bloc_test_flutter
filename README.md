# Offline-First Appointment Booking

A Flutter app for booking appointments that works fully offline. Pending
operations are queued locally and synced automatically when connectivity
returns. The bookings list is cache-first and paginated with infinite scroll.

---

## Running the app

### 1. Start the mock API server

```bash
dart pub get
dart run bin/server.dart        # serves http://localhost:8080
curl http://localhost:8080/admin/seed   # seed 25 demo bookings (optional)
```

### 2. Run the Flutter app

```bash
flutter pub get
flutter run
```

The base URL is resolved per platform in `lib/core/constants/api_constants.dart`:
`http://localhost:8080` on iOS/desktop and `http://10.0.2.2:8080` on the Android
emulator. Log in with **any** non-empty username/password.

### 3. Run the tests

```bash
flutter test
```

### Useful test endpoints

- `GET /admin/expire-token` — force the access token to expire (test refresh).
- `GET /admin/reset` / `GET /admin/seed` — reset / reseed data.
- `GET /pending-sync` — view the server's queued email-confirmation jobs.

---

## Architecture

Clean Architecture with three layers per feature (`auth`, `booking`):

```
feature/<name>/
  data/         models, datasources (remote = Retrofit, local = Drift), repository impl
  domain/       entities, repository interface, use cases
  presentation/ blocs, screens, widgets
core/           database (Drift), network (Dio + interceptors), services, DI, errors
```

Dependencies flow inward: presentation → domain ← data. The domain layer knows
nothing about Dio, Drift or Flutter. Wiring is done with `get_it`
(`core/di/injection.dart`). Errors are modelled as a `Failure` hierarchy and
returned via `Either<Failure, T>` (dartz), so the UI never has to catch
exceptions.

### Why BLoC for state management

The hardest part of this app is **coordinating asynchronous, long-lived
processes** — the sync engine drains a queue over time, emitting a stream of
distinct states (Syncing → Retrying → Conflict → Idle). That is a natural fit
for BLoC's event-in / state-stream-out model:

- The **Sync Engine** is a single `SyncBloc` — one shared instance registered as
  a singleton — making it the *single source of truth* required by Task 8. The
  UI simply renders whatever state it emits.
- Events make every state transition explicit and **testable** without a
  widget tree (see `test/`), and `equatable` gives cheap, correct rebuilds.
- It keeps side-effects (DB writes, API calls, the email queue) out of widgets.

### Offline-first sync engine

**Reads (cache-first).** `BookingRepository.getBookings` checks connectivity:
- **Online:** fetch the page from the API → upsert into Drift → return the page.
  Drift is always the source of truth on disk; a transient network error during
  an "online" fetch transparently falls back to the cache.
- **Offline:** serve straight from Drift (cursor pagination over `serverId`).

**Writes (queue).** Every CREATE/DELETE is recorded in a Drift
`pending_operations` table (Task 3) with a unique `local_uuid`, the operation
type, a JSON payload, and a timestamp. Offline creates also insert an
*optimistic* row in the `bookings` table (`syncStatus = 'pending'`) so the list
stays fully functional and the new booking is visible immediately at the top.

**Draining the queue.** When the device comes back online (detected via
`connectivity_plus`), `ConnectivityService.onStatusChange` dispatches
`SyncConnectivityChanged(true)` to the `SyncBloc`, which processes the queue
**sequentially in FIFO order** (`ORDER BY id ASC`). For each operation it emits
`SyncSyncing("Submitting Booking #A1B2C3…", processed, total)` so the UI shows
exactly which operation is in flight. On success the optimistic row is promoted
to a synced server row (its real `serverId` filled in) and the op is removed.

**Resilience / backoff.** Each operation is retried up to `maxRetriesPerOp`
times with exponential backoff (`Error_Retrying` between attempts). After
`maxConsecutiveFailures` operations fail in a row, the engine emits
`Paused_Backoff` and stops until the next connectivity event — so a flaky
network can't spin the queue.

The Sync Engine states map 1:1 to Task 8: `SyncIdle`, `SyncSyncing`,
`SyncConflictDetected`, `SyncPausedBackoff`, `SyncErrorRetrying`.

### Conflict handling

Conflicts are handled at the data-source boundary, where HTTP status is turned
into typed exceptions (`DoubleBookingException`, `NotFoundException`), then
resolved by whoever owns the operation:

- **404 on DELETE during sync** — the booking is already gone on the server, so
  this is *not* an error. The engine ignores it, drops the pending operation,
  and reflects the cancellation locally. (Dio's `validateStatus` lets 404/409
  through instead of throwing, so the data source inspects the status code and
  raises the right typed exception.)
- **409 on CREATE during sync** — the slot was taken on the server. The engine
  emits `SyncConflictDetected`, removes the optimistic row and the queued op
  (last-writer-wins / server-authoritative).
- **401 anywhere** — handled transparently by `RefreshTokenInterceptor`
  (see below), invisible to the sync engine.

### No double-booking (Task 4)

- **Offline / before every create:** a local Drift query checks for a confirmed
  booking with the same `doctor_id` + `booking_time`; if found, the create is
  rejected immediately with a `DoubleBookingFailure`.
- **Online:** the request goes to the server and a `409 Conflict` is mapped to
  the same `DoubleBookingFailure`.
- Either way the UI shows a friendly red snackbar.

### Authentication & token refresh (Task 2)

`flutter_secure_storage` holds the access/refresh tokens. Two Dio interceptors:
`AuthInterceptor` attaches `Authorization: Bearer <token>` to non-auth requests;
`RefreshTokenInterceptor` catches a `401`, calls `/auth/refresh` **once** (other
requests queue behind a single in-flight refresh), stores the new tokens, and
**retries the original request**. Test it with `GET /admin/expire-token`.

### Email confirmation queue (Task 5)

`EmailConfirmationService` is a single-worker FIFO queue. On any successful
create (online or synced from offline) a job is dispatched; jobs are processed
**one at a time** via `Future.delayed`, logging:

```
📧 Sending confirmation email for booking #42...
✅ Confirmation email sent for booking #42
```

### Pagination (Task 6)

Cursor-based, 10 per page. A `ScrollController` near the bottom dispatches
`LoadMoreBookings`; the `BookingBloc` appends the next page (deduped by
`serverId`) and shows a trailing spinner while `hasMore` is true.

---

## Tests

`test/booking_offline_sync_test.dart` (runs against an **in-memory Drift DB**):

| Test | What it proves |
|------|----------------|
| **Test 1 – Double-booking prevention** | A second create for the same doctor/time returns `DoubleBookingFailure` and never hits the network. |
| **Test 2 – Offline booking sync** | An offline create lands in `pending_operations` with a unique UUID; once online, `SyncBloc` drains the queue, the row is promoted to synced, and the queue empties. |
| **Test 3 – Email confirmation job** | A successful create dispatches an email job into the queue, which then drains. |
| *(bonus)* | An online `409` maps to `DoubleBookingFailure`. |

---

## Tech stack

Clean Architecture · BLoC (`flutter_bloc`) · Retrofit + Dio (interceptors) ·
Drift (local DB) · `flutter_secure_storage` · `connectivity_plus` · `get_it` ·
`dartz` · `equatable`.
