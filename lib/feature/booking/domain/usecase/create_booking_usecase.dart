import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entity/booking.dart';
import '../repository/booking_repository.dart';

class CreateBookingUsecase implements UseCase<Booking, CreateBookingParams> {
  final BookingRepository repository;

  CreateBookingUsecase(this.repository);

  @override
  Future<Either<Failure, Booking>> call(CreateBookingParams params) {
    return repository.createBooking(
      serviceId: params.serviceId,
      bookingTime: params.bookingTime,
      doctorId: params.doctorId,
    );
  }
}

class CreateBookingParams extends Equatable {
  final String serviceId;
  final String bookingTime;
  final String doctorId;

  const CreateBookingParams({
    required this.serviceId,
    required this.bookingTime,
    required this.doctorId,
  });

  @override
  List<Object?> get props => [serviceId, bookingTime, doctorId];
}
