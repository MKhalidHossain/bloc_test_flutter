import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/email_confirmation_service.dart';
import '../../domain/entity/booking.dart';
import '../../domain/repository/booking_repository.dart';
import '../datasource/booking_local_data_source.dart';
import '../datasource/booking_remote_data_source.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;
  final BookingLocalDataSource localDataSource;
  final ConnectivityService connectivityService;
  final EmailConfirmationService emailService;
  final Uuid uuid;

  BookingRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
    required this.emailService,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  // ---------------------------------------------------------------------------
  // Read (cache-first online, Drift-only offline) + pagination
  // ---------------------------------------------------------------------------
  @override
  Future<Either<Failure, BookingPage>> getBookings({
    String? cursor,
    int limit = 10,
  }) async {
    final online = await connectivityService.isOnline;
    if (online) {
      try {
        final response = await remoteDataSource.getBookings(
          limit: limit,
          cursor: cursor,
        );
        // Cache-first: store in Drift, then read back for display.
        await localDataSource.cacheBookings(response.data);
        final items = response.data.map((m) => m.toEntity()).toList();
        return Right(BookingPage(
          items: await _withPendingPrefix(items, cursor),
          nextCursor: response.pagination.nextCursor,
          hasMore: response.pagination.hasMore,
        ));
      } on ServerException catch (_) {
        // Network hiccup while "online" — fall back to the local cache.
        return Right(await _localPage(cursor: cursor, limit: limit));
      }
    }
    return Right(await _localPage(cursor: cursor, limit: limit));
  }

  /// Builds a page purely from Drift (offline path / fallback).
  Future<BookingPage> _localPage({String? cursor, int limit = 10}) async {
    final rows = await localDataSource.getSyncedPage(cursor: cursor, limit: limit);
    final hasMore = rows.length > limit;
    final pageRows = hasMore ? rows.sublist(0, limit) : rows;
    final items = pageRows.map(_rowToEntity).toList();
    final nextCursor =
        hasMore && pageRows.isNotEmpty ? pageRows.last.serverId?.toString() : null;
    return BookingPage(
      items: await _withPendingPrefix(items, cursor),
      nextCursor: nextCursor,
      hasMore: hasMore,
    );
  }

  /// Pending (offline-created) bookings are surfaced at the top of the first page.
  Future<List<Booking>> _withPendingPrefix(
    List<Booking> items,
    String? cursor,
  ) async {
    if (cursor != null) return items;
    final pending = await localDataSource.getPendingBookings();
    return [...pending.map(_rowToEntity), ...items];
  }

  // ---------------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------------
  @override
  Future<Either<Failure, Booking>> createBooking({
    required String serviceId,
    required String bookingTime,
    required String doctorId,
  }) async {
    // Task 4 — local double-booking guard, runs in both modes.
    final clash = await localDataSource.doubleBookingExists(
      doctorId: doctorId,
      bookingTime: bookingTime,
    );
    if (clash) {
      return const Left(
        DoubleBookingFailure('This doctor is already booked for that time slot.'),
      );
    }

    final online = await connectivityService.isOnline;
    if (online) {
      try {
        final created = await remoteDataSource.createBooking(
          CreateBookingRequest(
            serviceId: serviceId,
            bookingTime: bookingTime,
            doctorId: doctorId,
          ),
        );
        await localDataSource.cacheBookings([created]);
        emailService.dispatch('#${created.id}');
        return Right(created.toEntity());
      } on DoubleBookingException catch (e) {
        return Left(DoubleBookingFailure(e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    }

    // Offline: queue the operation + store an optimistic row.
    final localUuid = uuid.v4();
    final createdAt = DateTime.now().toIso8601String();
    await localDataSource.enqueueOperation(
      localUuid: localUuid,
      operationType: 'create',
      payload: jsonEncode({
        'service_id': serviceId,
        'booking_time': bookingTime,
        'doctor_id': doctorId,
      }),
      createdAt: createdAt,
    );
    final row = await localDataSource.insertOptimisticBooking(
      serviceId: serviceId,
      bookingTime: bookingTime,
      doctorId: doctorId,
      createdAt: createdAt,
      localUuid: localUuid,
    );
    return Right(_rowToEntity(row));
  }

  // ---------------------------------------------------------------------------
  // Cancel / delete
  // ---------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> cancelBooking(Booking booking) async {
    // A booking created offline that never reached the server: drop its queued
    // CREATE and remove the optimistic row — nothing to delete server-side.
    if (booking.isPending && booking.localUuid != null) {
      await localDataSource.deleteOperationByUuid(booking.localUuid!);
      await localDataSource.deleteByLocalUuid(booking.localUuid!);
      return const Right(unit);
    }

    final serverId = booking.serverId;
    if (serverId == null) {
      return const Left(ServerFailure('Cannot cancel a booking without an id.'));
    }

    final online = await connectivityService.isOnline;
    if (online) {
      try {
        await remoteDataSource.deleteBooking(serverId);
        await localDataSource.markCancelledByServerId(serverId);
        return const Right(unit);
      } on NotFoundException catch (_) {
        // Already gone on the server — treat as success (conflict handling).
        await localDataSource.markCancelledByServerId(serverId);
        return const Right(unit);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      }
    }

    // Offline: queue a DELETE and reflect it optimistically.
    await localDataSource.enqueueOperation(
      localUuid: uuid.v4(),
      operationType: 'delete',
      payload: jsonEncode({'server_id': serverId}),
      createdAt: DateTime.now().toIso8601String(),
    );
    await localDataSource.markCancelledByServerId(serverId);
    return const Right(unit);
  }

  Booking _rowToEntity(BookingRow row) => Booking(
        serverId: row.serverId,
        serviceId: row.serviceId,
        bookingTime: row.bookingTime,
        doctorId: row.doctorId,
        status: row.status,
        createdAt: row.createdAt,
        isPending: row.syncStatus == 'pending',
        localUuid: row.localUuid,
      );
}
