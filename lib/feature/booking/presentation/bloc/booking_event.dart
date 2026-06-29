import 'package:equatable/equatable.dart';

import '../../domain/entity/booking.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

/// Load (or reload) the first page.
class LoadBookings extends BookingEvent {
  const LoadBookings();
}

/// Infinite scroll — load the next page (Task 6).
class LoadMoreBookings extends BookingEvent {
  const LoadMoreBookings();
}

class CreateBookingRequested extends BookingEvent {
  final String serviceId;
  final String bookingTime;
  final String doctorId;
  const CreateBookingRequested({
    required this.serviceId,
    required this.bookingTime,
    required this.doctorId,
  });
  @override
  List<Object?> get props => [serviceId, bookingTime, doctorId];
}

class CancelBookingRequested extends BookingEvent {
  final Booking booking;
  const CancelBookingRequested(this.booking);
  @override
  List<Object?> get props => [booking];
}
