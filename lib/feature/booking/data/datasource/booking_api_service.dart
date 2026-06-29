import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../../../core/constants/api_constants.dart';
import '../models/booking_model.dart';

part 'booking_api_service.g.dart';

@RestApi()
abstract class BookingApiService {
  factory BookingApiService(Dio dio, {String baseUrl}) = _BookingApiService;

  @GET(ApiConstants.bookings)
  Future<BookingPageResponse> getBookings(
    @Query('limit') int limit,
    @Query('cursor') String? cursor,
  );

  /// Returns the raw HTTP response so the data source can distinguish 201
  /// (created) from 409 (double-booking conflict) — both pass Dio's
  /// `validateStatus`, so neither throws.
  @POST(ApiConstants.bookings)
  Future<HttpResponse<dynamic>> createBooking(@Body() CreateBookingRequest body);

  /// Returns the raw HTTP response so the data source can distinguish 200
  /// from 404 (already deleted on server).
  @DELETE('${ApiConstants.bookings}/{id}')
  Future<HttpResponse<dynamic>> deleteBooking(@Path('id') int id);
}
