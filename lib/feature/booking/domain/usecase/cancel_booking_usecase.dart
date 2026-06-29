import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entity/booking.dart';
import '../repository/booking_repository.dart';

class CancelBookingUsecase implements UseCase<Unit, Booking> {
  final BookingRepository repository;

  CancelBookingUsecase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(Booking params) {
    return repository.cancelBooking(params);
  }
}
