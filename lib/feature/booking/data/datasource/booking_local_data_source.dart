import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/booking_model.dart';

/// All Drift access for the booking feature: the cached bookings table and the
/// pending_operations FIFO queue.
class BookingLocalDataSource {
  final AppDatabase db;

  BookingLocalDataSource(this.db);

  // ---------------------------------------------------------------------------
  // Bookings cache
  // ---------------------------------------------------------------------------

  /// Upserts server bookings into the cache keyed by [serverId].
  Future<void> cacheBookings(List<BookingModel> bookings) async {
    await db.batch((batch) {
      for (final b in bookings) {
        batch.insert(
          db.bookings,
          BookingsCompanion.insert(
            serverId: Value(b.id),
            serviceId: b.serviceId,
            bookingTime: b.bookingTime,
            doctorId: b.doctorId,
            status: b.status,
            createdAt: b.createdAt,
            syncStatus: const Value('synced'),
          ),
          onConflict: DoUpdate(
            (_) => BookingsCompanion(
              serviceId: Value(b.serviceId),
              bookingTime: Value(b.bookingTime),
              doctorId: Value(b.doctorId),
              status: Value(b.status),
              createdAt: Value(b.createdAt),
              syncStatus: const Value('synced'),
            ),
            target: [db.bookings.serverId],
          ),
        );
      }
    });
  }

  /// Synced bookings only, paginated by descending server id (cursor = id).
  Future<List<BookingRow>> getSyncedPage({String? cursor, int limit = 10}) {
    final query = db.select(db.bookings)
      ..where((t) => t.syncStatus.equals('synced'));
    if (cursor != null) {
      final cursorId = int.tryParse(cursor);
      if (cursorId != null) {
        query.where((t) => t.serverId.isSmallerThanValue(cursorId));
      }
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.serverId)])
      ..limit(limit + 1); // +1 to detect "has more"
    return query.get();
  }

  /// Optimistic, not-yet-synced bookings (always shown at the top of the list).
  Future<List<BookingRow>> getPendingBookings() {
    return (db.select(db.bookings)
          ..where((t) => t.syncStatus.equals('pending'))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .get();
  }

  /// Local double-booking check: is there a confirmed booking for the same
  /// doctor and time slot?
  Future<bool> doubleBookingExists({
    required String doctorId,
    required String bookingTime,
  }) async {
    final rows = await (db.select(db.bookings)
          ..where((t) =>
              t.doctorId.equals(doctorId) &
              t.bookingTime.equals(bookingTime) &
              t.status.equals('confirmed')))
        .get();
    return rows.isNotEmpty;
  }

  /// Inserts an optimistic local booking (used for offline creates).
  Future<BookingRow> insertOptimisticBooking({
    required String serviceId,
    required String bookingTime,
    required String doctorId,
    required String createdAt,
    required String localUuid,
  }) async {
    final id = await db.into(db.bookings).insert(
          BookingsCompanion.insert(
            serviceId: serviceId,
            bookingTime: bookingTime,
            doctorId: doctorId,
            status: 'confirmed',
            createdAt: createdAt,
            syncStatus: const Value('pending'),
            localUuid: Value(localUuid),
          ),
        );
    return (db.select(db.bookings)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Promotes an optimistic row to a synced server booking.
  Future<void> markSynced(String localUuid, BookingModel server) async {
    await (db.update(db.bookings)..where((t) => t.localUuid.equals(localUuid)))
        .write(
      BookingsCompanion(
        serverId: Value(server.id),
        status: Value(server.status),
        createdAt: Value(server.createdAt),
        syncStatus: const Value('synced'),
      ),
    );
  }

  Future<void> markCancelledByServerId(int serverId) async {
    await (db.update(db.bookings)..where((t) => t.serverId.equals(serverId)))
        .write(const BookingsCompanion(status: Value('cancelled')));
  }

  Future<void> deleteByLocalUuid(String localUuid) async {
    await (db.delete(db.bookings)..where((t) => t.localUuid.equals(localUuid)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Pending operations queue
  // ---------------------------------------------------------------------------

  Future<void> enqueueOperation({
    required String localUuid,
    required String operationType,
    required String payload,
    required String createdAt,
  }) async {
    await db.into(db.pendingOperations).insert(
          PendingOperationsCompanion.insert(
            localUuid: localUuid,
            operationType: operationType,
            payload: payload,
            createdAt: createdAt,
          ),
        );
  }

  /// All pending operations in FIFO order.
  Future<List<PendingOperation>> getPendingOperations() {
    return (db.select(db.pendingOperations)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<int> pendingOperationCount() async {
    final rows = await db.select(db.pendingOperations).get();
    return rows.length;
  }

  Future<void> deleteOperation(int id) async {
    await (db.delete(db.pendingOperations)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteOperationByUuid(String localUuid) async {
    await (db.delete(db.pendingOperations)
          ..where((t) => t.localUuid.equals(localUuid)))
        .go();
  }
}
