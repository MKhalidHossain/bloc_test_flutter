import 'package:json_annotation/json_annotation.dart';

import '../../domain/entity/booking.dart';

part 'booking_model.g.dart';

/// Wire model for a booking as returned by / sent to the mock API.
@JsonSerializable()
class BookingModel {
  final int? id;
  @JsonKey(name: 'service_id')
  final String serviceId;
  @JsonKey(name: 'booking_time')
  final String bookingTime;
  @JsonKey(name: 'doctor_id')
  final String doctorId;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;

  BookingModel({
    this.id,
    required this.serviceId,
    required this.bookingTime,
    required this.doctorId,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) =>
      _$BookingModelFromJson(json);

  Map<String, dynamic> toJson() => _$BookingModelToJson(this);

  Booking toEntity() => Booking(
        serverId: id,
        serviceId: serviceId,
        bookingTime: bookingTime,
        doctorId: doctorId,
        status: status,
        createdAt: createdAt,
        isPending: false,
      );
}

/// Body for POST /bookings.
@JsonSerializable()
class CreateBookingRequest {
  @JsonKey(name: 'service_id')
  final String serviceId;
  @JsonKey(name: 'booking_time')
  final String bookingTime;
  @JsonKey(name: 'doctor_id')
  final String doctorId;

  CreateBookingRequest({
    required this.serviceId,
    required this.bookingTime,
    required this.doctorId,
  });

  factory CreateBookingRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBookingRequestToJson(this);
}

@JsonSerializable()
class PaginationModel {
  final int limit;
  @JsonKey(name: 'next_cursor')
  final String? nextCursor;
  @JsonKey(name: 'has_more')
  final bool hasMore;
  final int total;

  PaginationModel({
    required this.limit,
    this.nextCursor,
    required this.hasMore,
    required this.total,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) =>
      _$PaginationModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationModelToJson(this);
}

/// Envelope for GET /bookings: { "data": [...], "pagination": {...} }.
@JsonSerializable()
class BookingPageResponse {
  final List<BookingModel> data;
  final PaginationModel pagination;

  BookingPageResponse({required this.data, required this.pagination});

  factory BookingPageResponse.fromJson(Map<String, dynamic> json) =>
      _$BookingPageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BookingPageResponseToJson(this);
}

/// Envelope for POST /bookings: { "message": "...", "booking": {...} }.
@JsonSerializable()
class CreateBookingResponse {
  final String message;
  final BookingModel booking;

  CreateBookingResponse({required this.message, required this.booking});

  factory CreateBookingResponse.fromJson(Map<String, dynamic> json) =>
      _$CreateBookingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBookingResponseToJson(this);
}
