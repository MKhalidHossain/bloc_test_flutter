import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/core/database/app_database.dart';
import 'package:test/core/error/exceptions.dart';
import 'package:test/core/error/failure.dart';
import 'package:test/core/services/connectivity_service.dart';
import 'package:test/core/services/email_confirmation_service.dart';
import 'package:test/feature/booking/data/datasource/booking_local_data_source.dart';
import 'package:test/feature/booking/data/datasource/booking_remote_data_source.dart';
import 'package:test/feature/booking/data/models/booking_model.dart';
import 'package:test/feature/booking/data/repository/booking_repository_impl.dart';
import 'package:test/feature/booking/presentation/sync/sync_bloc.dart';
import 'package:test/feature/booking/presentation/sync/sync_event.dart';
import 'package:test/feature/booking/presentation/sync/sync_state.dart';

class MockRemote extends Mock implements BookingRemoteDataSource {}

class MockConnectivity extends Mock implements ConnectivityService {}

BookingModel _serverBooking({
  int id = 100,
  String doctorId = 'dr_1',
  String bookingTime = '2030-01-01T10:00:00.000',
  String status = 'confirmed',
}) =>
    BookingModel(
      id: id,
      serviceId: 'svc_1',
      bookingTime: bookingTime,
      doctorId: doctorId,
      status: status,
      createdAt: '2030-01-01T09:00:00.000',
    );

void main() {
  late AppDatabase db;
  late BookingLocalDataSource local;
  late MockRemote remote;
  late MockConnectivity connectivity;
  late EmailConfirmationService email;
  late BookingRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(CreateBookingRequest(
      serviceId: 's',
      bookingTime: 't',
      doctorId: 'd',
    ));
  });

  setUp(() {
    db = AppDatabase.inMemory();
    local = BookingLocalDataSource(db);
    remote = MockRemote();
    connectivity = MockConnectivity();
    // Fast email queue so onIdle resolves quickly in tests.
    email = EmailConfirmationService(sendDelay: const Duration(milliseconds: 1));
    repository = BookingRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      connectivityService: connectivity,
      emailService: email,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Test 1 — Double-booking prevention (local check)
  // ---------------------------------------------------------------------------
  test('Test 1: prevents double-booking for same doctor + time slot', () async {
    // A confirmed booking already exists in the local cache.
    await local.cacheBookings([
      _serverBooking(id: 1, doctorId: 'dr_9', bookingTime: '2030-05-05T14:00:00.000'),
    ]);
    when(() => connectivity.isOnline).thenAnswer((_) async => false);

    final result = await repository.createBooking(
      serviceId: 'svc_1',
      bookingTime: '2030-05-05T14:00:00.000',
      doctorId: 'dr_9',
    );

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<DoubleBookingFailure>()),
      (_) => fail('expected a DoubleBookingFailure'),
    );
    // No remote call and nothing queued.
    verifyNever(() => remote.createBooking(any()));
    expect(await local.pendingOperationCount(), 0);
  });

  // ---------------------------------------------------------------------------
  // Test 2 — Offline booking is queued, then synced when back online
  // ---------------------------------------------------------------------------
  test('Test 2: offline create is queued and synced on reconnect', () async {
    // --- Offline: create a booking ---
    when(() => connectivity.isOnline).thenAnswer((_) async => false);

    final created = await repository.createBooking(
      serviceId: 'svc_1',
      bookingTime: '2030-02-02T11:00:00.000',
      doctorId: 'dr_2',
    );
    expect(created.isRight(), isTrue);

    // It must be stored in pending_operations with a unique local UUID.
    final ops = await local.getPendingOperations();
    expect(ops.length, 1);
    expect(ops.first.operationType, 'create');
    expect(ops.first.localUuid, isNotEmpty);

    // An optimistic (pending) booking is visible locally.
    expect((await local.getPendingBookings()).length, 1);

    // --- Back online: the sync engine drains the queue ---
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => remote.createBooking(any()))
        .thenAnswer((_) async => _serverBooking(id: 555, doctorId: 'dr_2'));

    final sync = SyncBloc(
      localDataSource: local,
      remoteDataSource: remote,
      connectivityService: connectivity,
      emailService: email,
    );
    addTearDown(sync.close);

    sync.add(const SyncRequested());
    final terminal = await sync.stream.firstWhere(
      (s) => s is SyncIdle || s is SyncPausedBackoff,
    );

    expect(terminal, isA<SyncIdle>());
    // Queue drained, optimistic row promoted to a synced server booking.
    expect(await local.pendingOperationCount(), 0);
    expect((await local.getPendingBookings()), isEmpty);
    verify(() => remote.createBooking(any())).called(1);

    final synced = await local.getSyncedPage();
    expect(synced.any((b) => b.serverId == 555), isTrue);
  });

  // ---------------------------------------------------------------------------
  // Test 3 — Email confirmation job dispatched on successful create
  // ---------------------------------------------------------------------------
  test('Test 3: email confirmation job dispatched on successful create', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => remote.createBooking(any()))
        .thenAnswer((_) async => _serverBooking(id: 42, doctorId: 'dr_3'));

    // Use a slower send so we can observe the job sitting in the queue.
    final slowEmail =
        EmailConfirmationService(sendDelay: const Duration(milliseconds: 200));
    final repo = BookingRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      connectivityService: connectivity,
      emailService: slowEmail,
    );

    final result = await repo.createBooking(
      serviceId: 'svc_1',
      bookingTime: '2030-03-03T09:00:00.000',
      doctorId: 'dr_3',
    );
    expect(result.isRight(), isTrue);

    // A job was dispatched for booking #42.
    expect(slowEmail.pendingJobs, contains('#42'));

    // And it drains to completion.
    await slowEmail.onIdle;
    expect(slowEmail.pendingJobs, isEmpty);
  });

  // ---------------------------------------------------------------------------
  // Bonus — online 409 surfaces as a DoubleBookingFailure
  // ---------------------------------------------------------------------------
  test('online create maps server 409 to DoubleBookingFailure', () async {
    when(() => connectivity.isOnline).thenAnswer((_) async => true);
    when(() => remote.createBooking(any()))
        .thenThrow(DoubleBookingException('Doctor already booked'));

    final result = await repository.createBooking(
      serviceId: 'svc_1',
      bookingTime: '2030-04-04T08:00:00.000',
      doctorId: 'dr_4',
    );

    expect(result.fold((l) => l, (r) => r), isA<DoubleBookingFailure>());
  });
}
