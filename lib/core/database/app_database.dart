import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Local cache of bookings.
///
/// We keep a local autoincrement [id] as the Drift primary key so that
/// bookings created while offline (which have no server id yet) can still be
/// stored. The real server id lives in [serverId] and is filled in once the
/// pending CREATE operation is synced.
@DataClassName('BookingRow')
class Bookings extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The id assigned by the server. Null until a pending CREATE is synced.
  /// Unique so we can upsert cached bookings by server id (NULLs stay distinct
  /// in SQLite, so multiple offline-pending rows don't collide).
  IntColumn get serverId => integer().nullable().unique()();

  TextColumn get serviceId => text()();
  TextColumn get bookingTime => text()();
  TextColumn get doctorId => text()();
  TextColumn get status => text()();
  TextColumn get createdAt => text()();

  /// 'synced' when the row mirrors the server, 'pending' when it only exists
  /// locally and is waiting for a queued operation to be processed.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('synced'))();

  /// Links an optimistic local row to its entry in [PendingOperations].
  TextColumn get localUuid => text().nullable()();
}

/// FIFO queue of CREATE / DELETE operations performed while offline (or that
/// failed online and need a retry).
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localUuid => text().unique()();

  /// 'create' or 'delete'.
  TextColumn get operationType => text()();

  /// JSON-encoded payload for the operation.
  TextColumn get payload => text()();
  TextColumn get createdAt => text()();
}

@DriftDatabase(tables: [Bookings, PendingOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'appointments_db'));

  @override
  int get schemaVersion => 1;

  /// Convenience constructor for tests: an in-memory database.
  factory AppDatabase.inMemory() =>
      AppDatabase(_inMemoryExecutor());
}

QueryExecutor _inMemoryExecutor() {
  return NativeDatabase.memory();
}
