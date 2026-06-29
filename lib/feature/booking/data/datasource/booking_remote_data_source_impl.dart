import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import 'booking_api_service.dart';
import '../models/booking_model.dart';
import 'booking_remote_data_source.dart';

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final BookingApiService apiService;

  BookingRemoteDataSourceImpl({required this.apiService});

  @override
  Future<BookingPageResponse> getBookings({
    required int limit,
    String? cursor,
  }) async {
    try {
      return await apiService.getBookings(limit, cursor);
    } on DioException catch (e) {
      throw ServerException(_message(e));
    }
  }

  @override
  Future<BookingModel> createBooking(CreateBookingRequest request) async {
    try {
      final http = await apiService.createBooking(request);
      final status = http.response.statusCode;
      final data = http.data;

      if (status == 201) {
        final booking = (data as Map<String, dynamic>)['booking']
            as Map<String, dynamic>;
        return BookingModel.fromJson(booking);
      }
      if (status == 409) {
        throw DoubleBookingException(
          _errorMessage(data, 'Doctor already booked for this time slot'),
        );
      }
      throw ServerException(_errorMessage(data, 'Failed to create booking'));
    } on DioException catch (e) {
      throw ServerException(_message(e));
    }
  }

  @override
  Future<void> deleteBooking(int serverId) async {
    try {
      final http = await apiService.deleteBooking(serverId);
      final status = http.response.statusCode;
      if (status == 200) return;
      if (status == 404) {
        throw NotFoundException(
          _errorMessage(http.data, 'Booking not found'),
        );
      }
      throw ServerException(_errorMessage(http.data, 'Failed to cancel booking'));
    } on DioException catch (e) {
      throw ServerException(_message(e));
    }
  }

  String _errorMessage(dynamic data, String fallback) {
    if (data is Map && data['error'] != null) return data['error'].toString();
    return fallback;
  }

  String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) return data['error'].toString();
    return e.message ?? 'Network error';
  }
}
