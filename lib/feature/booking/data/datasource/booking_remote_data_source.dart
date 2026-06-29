import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<BookingPageResponse> getBookings({required int limit, String? cursor});

  /// Creates a booking on the server.
  /// Throws [DoubleBookingException] on 409, [ServerException] otherwise.
  Future<BookingModel> createBooking(CreateBookingRequest request);

  /// Deletes a booking on the server.
  /// Throws [NotFoundException] on 404, [ServerException] otherwise.
  Future<void> deleteBooking(int serverId);
}
