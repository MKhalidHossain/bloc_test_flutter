import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entity/booking.dart';

abstract class BookingRepository {
  /// Cache-first when online (fetch from API -> store in Drift -> read back),
  /// and Drift-only when offline.
  Future<Either<Failure, BookingPage>> getBookings({
    String? cursor,
    int limit = 10,
  });

  /// Creates a booking. Online: hits the API and handles 409 double-booking.
  /// Offline: enqueues a pending CREATE operation and stores an optimistic row.
  /// In both modes a local double-booking check runs first.
  Future<Either<Failure, Booking>> createBooking({
    required String serviceId,
    required String bookingTime,
    required String doctorId,
  });

  /// Cancels a booking. Online: DELETE on the server. Offline: enqueues a
  /// pending DELETE (or cancels a not-yet-synced create outright).
  Future<Either<Failure, Unit>> cancelBooking(Booking booking);
}
