import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entity/booking.dart';
import '../repository/booking_repository.dart';

class GetBookingsUsecase implements UseCase<BookingPage, GetBookingsParams> {
  final BookingRepository repository;

  GetBookingsUsecase(this.repository);

  @override
  Future<Either<Failure, BookingPage>> call(GetBookingsParams params) {
    return repository.getBookings(cursor: params.cursor, limit: params.limit);
  }
}

class GetBookingsParams extends Equatable {
  final String? cursor;
  final int limit;

  const GetBookingsParams({this.cursor, this.limit = 10});

  @override
  List<Object?> get props => [cursor, limit];
}
