// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookingModel _$BookingModelFromJson(Map<String, dynamic> json) => BookingModel(
  id: (json['id'] as num?)?.toInt(),
  serviceId: json['service_id'] as String,
  bookingTime: json['booking_time'] as String,
  doctorId: json['doctor_id'] as String,
  status: json['status'] as String,
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$BookingModelToJson(BookingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'service_id': instance.serviceId,
      'booking_time': instance.bookingTime,
      'doctor_id': instance.doctorId,
      'status': instance.status,
      'created_at': instance.createdAt,
    };

CreateBookingRequest _$CreateBookingRequestFromJson(
  Map<String, dynamic> json,
) => CreateBookingRequest(
  serviceId: json['service_id'] as String,
  bookingTime: json['booking_time'] as String,
  doctorId: json['doctor_id'] as String,
);

Map<String, dynamic> _$CreateBookingRequestToJson(
  CreateBookingRequest instance,
) => <String, dynamic>{
  'service_id': instance.serviceId,
  'booking_time': instance.bookingTime,
  'doctor_id': instance.doctorId,
};

PaginationModel _$PaginationModelFromJson(Map<String, dynamic> json) =>
    PaginationModel(
      limit: (json['limit'] as num).toInt(),
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool,
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationModelToJson(PaginationModel instance) =>
    <String, dynamic>{
      'limit': instance.limit,
      'next_cursor': instance.nextCursor,
      'has_more': instance.hasMore,
      'total': instance.total,
    };

BookingPageResponse _$BookingPageResponseFromJson(Map<String, dynamic> json) =>
    BookingPageResponse(
      data: (json['data'] as List<dynamic>)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationModel.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$BookingPageResponseToJson(
  BookingPageResponse instance,
) => <String, dynamic>{
  'data': instance.data,
  'pagination': instance.pagination,
};

CreateBookingResponse _$CreateBookingResponseFromJson(
  Map<String, dynamic> json,
) => CreateBookingResponse(
  message: json['message'] as String,
  booking: BookingModel.fromJson(json['booking'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CreateBookingResponseToJson(
  CreateBookingResponse instance,
) => <String, dynamic>{
  'message': instance.message,
  'booking': instance.booking,
};
